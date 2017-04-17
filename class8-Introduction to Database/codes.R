#RSQL
#1.操作关系型数据库——以SQLite为例
#install.packages("RSQLite")
#载入RSQLite包
library(RSQLite)
#提供一个数据库驱动和数据库文件来建立连接：
con <- dbConnect(SQLite( ), "data/example1.sqlite")

dbListTables(con)
dbExistsTable(con, "student")
dbExistsTable(con, "students")
dbListFields(con, "student")
studentInfo <- dbReadTable(con,"student");studentInfo

dbWriteTable(con,"studentcopy",studentInfo)#用于向一个数据库写入表格，或者追加一些数据
dbListTables(con)
dbRemoveTable(con,"studentcopy")#删除数据库中指定表
dbListTables(con)

dbDisconnect(con)

#用SQL查询
con <- dbConnect(SQLite( ), "data/example2.sqlite")
data("diamonds", package ="ggplot2")

#1.SQL：select选取列
#基本SQL语法：Select <列名> from <表名>;

#* 这个符号代表所有的字段。如果我们只需要字段的一个子集，也可以依次列出字段名
db_diamonds <- dbGetQuery(con,
                          "select * from diamonds")
head(db_diamonds, 3)

#选择部分字段
db_diamonds <- dbGetQuery(con,
                          "select carat, cut, color, clarity, depth, price from diamonds")
head(db_diamonds, 3)

#select distinct:选取数据中所有不重复的值
dbGetQuery(con, "select distinct cut from diamonds")

#更改显示结果的列名
db_diamonds <- dbGetQuery(con, 
                          "select carat, price, clarity as clarity_level from diamonds")
head(db_diamonds, 3)
#还可以显示一些不直接存储在数据库中，而是需要经过一些计算才能得到的值。这时，也可以使用 A as B 语句形式
db_diamonds <- dbGetQuery(con,
                          "select carat, price, x * y * z as size from diamonds")
head(db_diamonds, 3)


#进阶：嵌套
#要求：用现有列生成一个新列，再用该新列生成另一个列
db_diamonds <- dbGetQuery(con,
                          "select carat, price, x * y * z as size,
                          price / size as value_density
                          from diamonds")#报错
#解决方案：语句嵌套
db_diamonds <- dbGetQuery(con,
                          "select *, price / size as value_density from
                          (select carat, price, x * y * z as size
                          from diamonds)")
head(db_diamonds,3)
#在这种情况下，当计算 price/size 时，size 已经在临时表中定义了。


#2.SQL：where条件查询

#使用where 来指明查询结果应满足的条件。例如，选择 cut 值为 good 的钻石数据：
good_diamonds <- dbGetQuery(con,
                            "select carat, cut, price from diamonds 
                            where cut = 'Good'")
head(good_diamonds, 3)

#如果查询需要同时满足多个条件，用and,or,not连接多个条件
good_e_diamonds <- dbGetQuery(con,
                              "select carat, cut, color, price 
                              from diamonds
                              where cut = 'Good' and color = 'E'")
head(good_e_diamonds, 3)


#上述每个条件都只涉及一个取值，如何选取取值在某集合的数据？——in
color_ef_diamonds <- dbGetQuery(con,
                                "select carat, cut, color, price 
                                from diamonds
                                where color in ('E', 'F')")
nrow(color_ef_diamonds)
table(diamonds$color)#验证结果

#in:指定集合；between...and...：指定区间：数字，字符（按字典排列顺序）等可比的类型均可
some_price_diamonds <- dbGetQuery(con,
                                  "select carat, cut, color, price 
                                  from diamonds
                                  where price between 5000 and 5500")


#like:筛选具有某种模式的字段；通配符：用于代表任意字符

#  _ :代表任意*一个*字符
#  % ：代表任意*多个*字符
# [charlist]:字符列中的任何单一字符
# [^charlist]或者[!charlist]:不在字符列中的任何单一字符


#选出表中 cut 变量的取值是以 Good 结尾的记录
good_cut_diamonds <- dbGetQuery(con,
                                "select carat, cut, color, price 
                                from diamonds           
                                where cut like '%Good' ")
nrow(good_cut_diamonds) /nrow(diamonds)

#order by：按指定字段重新排列数据
cheapest_diamonds <- dbGetQuery(con,
                                "select carat, price from diamonds
                                order by price")
head(cheapest_diamonds)
#默认升序（asc）,降序加desc
most_expensive_diamonds <- dbGetQuery(con,
                                      "select carat, price from diamonds
                                      order by price desc")
head(most_expensive_diamonds)

#根据多个字段排序
cheapest_diamonds <- dbGetQuery(con,
                                "select carat, price from diamonds
                                order by price, carat desc")
head(cheapest_diamonds)
#用于排序的列可以是根据已有列计算生成的
dense_diamonds <- dbGetQuery(con,
                             "select carat, price, x * y * z as size 
                             from diamonds
                             order by carat /size desc")
#where 和 order by 便可得到一个排序的子集结果
head(dbGetQuery(con,
                "select carat, price from diamonds
                where cut = 'Ideal' and clarity = 'IF' and color = 'J'
                order by price"))


#对记录进行分组聚合
dbGetQuery(con,
           "select color, count(*) as number from diamonds
           group by color")
table(diamonds$color)#检验查询结果
#聚合函数： avg( )、max( )、min( ) 和 sum( )
#计算不同透明度水平的平均价格
dbGetQuery(con,
           "select clarity, avg(price) as avg_price
           from diamonds
           group by clarity
           order by avg_price desc")

#还可以在组内同时进行多个运算
dbGetQuery(con,
           "select clarity,
           min(price) as min_price,
           max(price) as max_price,
           avg(price) as avg_price
           from diamonds
           group by clarity
           order by avg_price desc")

#还可根据多字段进行分组
dbGetQuery(con,
           "select clarity, color,
           avg(price) as avg_price
           from diamonds
           group by clarity, color
           order by avg_price desc")

dbDisconnect(con)


#多表查询
con <- dbConnect(SQLite( ), "data/example1.sqlite")

dbGetQuery(con,
           "select * from course")
dbGetQuery(con,
           "select * from teacher")
dbGetQuery(con,
           "select * from course,teacher")

dbGetQuery(con,
           "select * from course,teacher where course.Teacher=teacher.ID")
#使用join 也能达到相同的效果,但注意语法上的细微差别
dbGetQuery(con,
           "select * from course join teacher on course.Teacher=teacher.ID")

dbGetQuery(con,
           "select course.ID as courseID,course.name as courseName,teacher.name as teacher from course,teacher 
           where course.Teacher=teacher.ID")
dbGetQuery(con,
           "select course.ID as courseID,course.name as courseName,teacher.name as teacher from course,teacher 
           where course.Teacher=teacher.ID")

dbDisconnect(con)

##分块提取查询结果
con <- dbConnect(SQLite( ), "data/example2.sqlite")
res <- dbSendQuery(con,
                   "select carat, cut, color, price from diamonds
where cut = 'Ideal' and color = 'E' ")
while(!dbHasCompleted(res)){
  chunk <- dbFetch(res, 800)
  cat(nrow(chunk), "records fetched\n")
}
dbClearResult(res)
dbDisconnect(con)
