#include<Rcpp.h>
using namespace Rcpp;

//all()
//[[Rcpp::export]]
bool allC(LogicalVector x)
{
	int n=x.size();
	for(int i=0;i<n;i++)
	{if (!x[i]) return false;}
	return true;
}
/***R
test1=c(T,T,T);test2=c(T,F,T)
allC(test1);allC(test2)
*/

//cumprod cummin 
//[[Rcpp::export]]
NumericVector cumprodC(NumericVector x)
{
	int n=x.size();
	NumericVector out(n);
	out[0]=x[0];
	for (int i=1;i<n;i++)
	{out[i]=out[i-1]*x[i];}
	return out;
}
//[[Rcpp::export]]
NumericVector cumminC(NumericVector x)
{
	int n=x.size();
	NumericVector out(n);
	out[0]=x[0];
	for (int i=1;i<n;i++)
	{if(x[i]<out[i-1]) out[i]=x[i];
	else out[i]=out[i-1];}
	return out;
}
/***R
test=c(2,3,4,1,3)
test
cumprodC(test);cumminC(test)
*/

//diff lag=1~n
//[[Rcpp::export]]
NumericVector diffC(NumericVector x,int lag=1)
{
	int n=x.size()-lag;
	NumericVector out(n);
	for (int i=0;i<n;i++)
	{out[i]=x[i+lag]-x[i];}
	return out;
}
/***R
test=c(2,3,4,1,3)
test
diffC(test)
*/


//range
//[[Rcpp::export]]
NumericVector rangeC(NumericVector x)
{
	int n=x.size();
	NumericVector out(2);
	out[0]=x[0];
	out[1]=x[0];
	for (int i=1;i<n;i++)
	{
		if (x[i]<out[0]) out[0]=x[i];
		else if(x[i]>out[1]) out[1]=x[i];
		else continue;
	}
	return out;
}
/***R
test
rangeC(test)
*/

//var
//[[Rcpp::export]]
double varC(NumericVector x)
{
	int n=x.size();
	double total=0;
	double totalsqared=0;
	double out;
	for (int i=0;i<n;i++)
	{
		total+=x[i];
		totalsqared+=pow(x[i],2.0);
	}
	out=(totalsqared/(n-1))-(n/n+1*pow(total/n,2.0));
	return(out);
}
/***R
test
varC(test)
*/