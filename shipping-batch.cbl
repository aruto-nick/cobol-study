000001*2*3*4567A901B3456789012345678901234567890123456789012345678901234

      * 見出し部:プログラム名・作成者
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHIPPING-BATCH.
       AUTHOR. ARUTO-OKAMOTO.

      * 環境部:使用する外部ファイルを記述
       ENVIRONMENT DIVISION.
      * 入出力節：使用する外部ファイルと物理ファイルを結びつける
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      *外部ファイル「input/orders.dat」とプログラム内ファイル「ORDER-FILE」接続
               SELECT ORDER-FILE ASSIGN TO "input/orders.dat"
                   ORGANIZATION IS LINE SEQUENTIAL.
               SELECT SHIPPING-FILE ASSIGN TO "output/shipping.dat"
                   ORGANIZATION IS LINE SEQUENTIAL.
               SELECT ERROR-FILE ASSIGN TO "output/shipping-error.dat"
                   ORGANIZATION IS LINE SEQUENTIAL.
               SELECT STOCK-FILE ASSIGN TO "input/stocks.dat"
                   ORGANIZATION IS LINE SEQUENTIAL.
 
 
      * データ部：すべての変数やファイル構造を定義
       DATA DIVISION.
       FILE SECTION.


      * ORDER-FILEの構造定義：注文ID・商品コード・注文数
       FD ORDER-FILE.
       01 ORDER-RECORD.
      *PIC＝ 定義、X=文字、9＝数字、A＝アルファベット、V＝小数点
      *階層番号01=最上位
           05 IN-ORDER-ID PIC X(6).
           05 IN-PRODUCT-CODE PIC X(5).
           05 IN-ORDER-QTY PIC 9(3).
                
      * SHIPPING-FILEの構造定義：注文ID・商品コード・注文数・引当後在庫数
       FD SHIPPING-FILE.
       01 SHIPPING-RECORD.
           05 OUT-ORDER-ID PIC X(6).
           05 OUT-PRODUCT-CODE PIC X(5).
           05 OUT-ORDER-QTY PIC 9(3).
           05 OUT-REMAINING-STOCK PIC 9(3).

      * ERROR-FILEの内部構造定義：注文ID・商品コード・注文数・在庫数・エラー原因
       FD ERROR-FILE.
       01 ERROR-RECORD.
           05 ERR-ORDER-ID PIC X(6).
           05 ERR-PRODUCT-CODE PIC X(5).
           05 ERR-ORDER-QTY PIC 9(3).
           05 ERR-STOCK-QTY PIC 9(3).
           05 ERR-REASON PIC X(17).

      * STOCK-FILEの内部構造定義：商品コード・在庫数
       FD STOCK-FILE.
       01 STOCK-RECORD.
           05 MST-PRODUCT-CODE PIC X(5).
           05 MST-STOCK-QTY PIC 9(3).

      * 変数を定義：①在庫数②ファイル読込み確認③合計（④＋⑤）④出荷数⑤エラー数
      * VALUE = 初期値         
       WORKING-STORAGE SECTION.
       01 WS-STOCK-QTY PIC 9(3) VALUE 0.
       01 WS-EOF PIC X VALUE "N".
       01 WS-TOTAL-COUNT PIC 9(3) VALUE 0.
       01 WS-SHIPPING-COUNT PIC 9(3) VALUE 0.
       01 WS-ERROR-COUNT PIC 9(3) VALUE 0.


      * 手続き部：実際の処理
       PROCEDURE DIVISION.
      * 内部ファイルと外部ファイルを開く
           OPEN INPUT ORDER-FILE STOCK-FILE
                OUTPUT SHIPPING-FILE ERROR-FILE
      
      * 在庫ファイル読込み：在庫数を保持する
      * AT END （ファイル終端時の処理）NOT AT END (データ読み込み成功時の処理)
           READ STOCK-FILE
               AT END
                   DISPLAY "STOCK FILE IS EMPTY"
               NOT AT END
                   MOVE MST-STOCK-QTY TO WS-STOCK-QTY
           END-READ
           
      * 注文ファイル読込み。未処理の注文ファイルがなくなるまで繰り返す
           PERFORM UNTIL WS-EOF = "Y"
                  READ ORDER-FILE 
      * 読込みファイルがなくなれば、ファイル読込み終了
                   AT END
                       MOVE "Y" TO WS-EOF
      * 未読込み注文ファイルがあれば、
                   NOT AT END
      * 総処理件数に1加算
                       ADD 1 TO WS-TOTAL-COUNT
      * 表示：注文ID・商品コード・在庫数・注文数
                       DISPLAY "ORDER ID : "IN-ORDER-ID
                       DISPLAY "PRODUCT CODE : " IN-PRODUCT-CODE
                       DISPLAY "STOCK QTY : "WS-STOCK-QTY
                       DISPLAY "ORDER QTY : " IN-ORDER-QTY
       
      * 【商品コードの照合】商品コードと在庫商品コードが一致した場合、出荷処理
                       IF IN-PRODUCT-CODE = MST-PRODUCT-CODE
       
      * 【商品コード一致】＆【在庫数が注文数以上】：在庫数から注文数を引く
                           IF IN-ORDER-QTY <= WS-STOCK-QTY
                               SUBTRACT IN-ORDER-QTY FROM WS-STOCK-QTY
      * 入力データと引当後在庫を出力レコードへ移す
                               MOVE IN-ORDER-ID TO OUT-ORDER-ID
                               MOVE IN-PRODUCT-CODE TO OUT-PRODUCT-CODE
                               MOVE IN-ORDER-QTY TO OUT-ORDER-QTY
                               MOVE WS-STOCK-QTY TO OUT-REMAINING-STOCK
      * 出荷ファイルへ書き込み後、出荷数＋１、表示：出荷可能＆残り在庫数
                               WRITE SHIPPING-RECORD
                               ADD 1 TO WS-SHIPPING-COUNT
                               display "RESULT : SHIPPING AVAILABLE"
                               display "REMAINING STOCK : "WS-STOCK-QTY
                           ELSE
      * 【商品コード一致】＆【出荷失敗時（注文＞在庫）】、エラーレコードにデータ移す
                               MOVE IN-ORDER-ID TO ERR-ORDER-ID
                               MOVE IN-PRODUCT-CODE TO ERR-PRODUCT-CODE
                               MOVE IN-ORDER-QTY TO ERR-ORDER-QTY
                               MOVE WS-STOCK-QTY TO ERR-STOCK-QTY
                               MOVE "OUT OF STOCK" TO ERR-REASON
      * エラーファイルに書き込み後、エラー件数＋１、表示「在庫不足・残り在庫数」
                               WRITE ERROR-RECORD
                               ADD 1 TO WS-ERROR-COUNT
                               DISPLAY "RESULT : OUT OF STOCK"
                               DISPLAY "REMAINING STOCK : " WS-STOCK-QTY
                           END-IF
       
                  
      * 【商品コードの照合】一致する商品コードなしの場合
                       ELSE
       
      * 商品未登録としてエラーファイルに書き込み、エラー件数＋１、表示「商品なし」
                           MOVE IN-ORDER-ID TO ERR-ORDER-ID
                           MOVE IN-PRODUCT-CODE TO ERR-PRODUCT-CODE
                           MOVE IN-ORDER-QTY TO ERR-ORDER-QTY
                           MOVE 0 TO ERR-STOCK-QTY
                           MOVE "PRODUCT NOT FOUND" TO ERR-REASON
                           WRITE ERROR-RECORD
                           ADD 1 TO WS-ERROR-COUNT
                           DISPLAY "RESULT : PRODUCT NOT FOUND"
                       END-IF
                  END-READ
           END-PERFORM

      * 【件数集計】バッチ処理の結果を表示
           DISPLAY "BATCH PROCESSING SUMMARY"
           DISPLAY "TOTAL ORDERS : " WS-TOTAL-COUNT
           DISPLAY "SHIPPED ORDERS : " WS-SHIPPING-COUNT
           DISPLAY "ERROR ORDERS : " WS-ERROR-COUNT
           DISPLAY "FINAL PRODUCT : " MST-PRODUCT-CODE
           DISPLAY "FINAL STOCK : " WS-STOCK-QTY

           CLOSE ORDER-FILE STOCK-FILE SHIPPING-FILE ERROR-FILE
           STOP RUN.
