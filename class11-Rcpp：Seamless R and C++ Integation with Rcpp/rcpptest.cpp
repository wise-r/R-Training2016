#include<Rcpp.h> //头文件
using namespace Rcpp; //使用命名空间。如无，则第7行需书写Rcpp::NumericVector 等


//添加了//[[Rcpp::export]]的函数会被export至R，这是新版本Rcpp的一个重要特性
//[[Rcpp::export]]
double meanC(NumericVector x)        
{
	int n=x.size(); //x是NumericVector类对象，x.size()类方法
	double total=0;
	for (int i=0;i<n;i++)
	{total+=x[i];}
	return total/n;
}

//使用/***R some R codes */
//可以很方便的在cpp文件中插入R代码，在使用sourceCpp时，这段代码也会被eval
/***R
library(microbenchmark)
x=runif(1e5)
microbenchmark(mean(x),meanC(x))
*/