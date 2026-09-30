#!/bin/csh

# (1) 初期設定・開始日時取得

# ログファイルの保存先を設定
set LOG_FILE = "output/shipping-batch.log"

# バッチ開始日時取得
set START_TIME = "`date '+%Y-%m-%d %H:%M:%S'`"

echo "START SHIPPING BATCH"
echo "START TIME : $START_TIME"
echo "START TIME : $START_TIME" >! $LOG_FILE

# (2) 入力ファイルの存在確認

# 注文ファイルの存在確認
if ( ! -e input/orders.dat ) then
    echo "ORDERS FILE NOT FOUND"
    exit 1
endif

# 在庫ファイルの存在確認
if ( ! -e input/stocks.dat ) then
    echo "STOCKS FILE NOT FOUND"
    exit 1
endif

echo "INPUT FILE CHECK SUCCESS"

# (3) COBOLプログラムのコンパイル

# COBOLファイルを固定形式でコンパイル
echo "COMPILING COBOL PROGRAM"
cobc -x -fixed shipping-batch.cbl -o shipping-batch

# コンパイル失敗の場合、「コンパイルエラー」表示
if ( $status != 0 ) then
    echo "COMPILE ERROR"
    exit 1
endif

# コンパイル成功の場合、「コンパイル成功」と表示
echo "COMPILE SUCCESS"

# (4) バッチ実行・ログ保存

echo "RUNNING SHIPPING BATCH"

# 実行可能ファイルを起動して、画面出力とエラー出力をログへ保存
./shipping-batch >>& $LOG_FILE

# tail実行前に、バッチの終了ステータスを保存
set BATCH_STATUS = $status

# ログの2行目以降を表示（開始日時の二重表示を防ぐため）
tail -n +2 $LOG_FILE

# バッチの実行結果が失敗の場合、「エラー」表示
if ( $BATCH_STATUS != 0 ) then
    echo "BATCH EXECUTION ERROR"
    exit 1
endif

# (5) バッチ終了日時取得

set END_TIME = "`date '+%Y-%m-%d %H:%M:%S'`"

# 終了日時を画面とログへ出力
echo "END TIME : $END_TIME"
echo "END TIME : $END_TIME" >> $LOG_FILE

# (6) 正常終了

# 正常終了を画面とログへ出力
echo "BATCH EXECUTION SUCCESS"
echo "BATCH EXECUTION SUCCESS" >> $LOG_FILE

# C-Shellを正常終了
exit 0