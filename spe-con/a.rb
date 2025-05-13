#A8
grid = [
  [2, 0, 0, 5, 1],
  [1, 0, 3, 0, 0],
  [0, 8, 5, 0, 2],
  [4, 1, 0, 0, 6],
  [0, 9, 2, 7, 0]
]

#以下の範囲のフィールドの合計値を出力
queries = [
  [2, 2, 4, 5],
  [1, 1, 5, 5]
]

#A9 

primes = [11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67]

#A11 
#ターゲットのあたいがmiddleより上か？
#はい⇨(middle..last)で配列作成
#いいえ⇨(left..middle)で配列作成


# item_num, max_value = gets.chomp.split.map(&:to_i)

# weight,value = item_num.times.inject([]){|array|array << gets.chomp.split.map(&:to_i)}.transpose


# combination =  Array.new(item_num){Array.new(max_value,0)}

# (1..item_num).each do |item_index|
# (0...max_value).each do |index|
#   if index < weight[index]
#   combination[item_index][index] = value[index]
#   end 
# end 
# end

#①全体の要素の数の半分の値を計算する
#②探す値と配列の半分の値を比べる
#③探す値の方が大きい⇨leftをmiddle + 1 
#③探す値が小さい⇨right をmiddle -1

#ハッシュを作成する
#eachで配列を回す
#ハッシュのキーにない場合ハッシュに挿入、ある場合eachの処理を止めてその値を出力


