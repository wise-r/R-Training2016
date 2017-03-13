library(data.table)
library(rlist)
library(pipeR)

RunBackTest <- function(para)
{
  N <- para$N
  lossrate <- para$lossrate
  
  cdt <- copy(dt)  # 一定要显式的copy
  # 生成N_high, N_low 
  cdt[, `:=`(
    N_high = shift(TTR::runMax(high, n = N), n = 1, type = "lag"),
    N_low = shift(TTR::runMin(low, n = N), n = 1, type = "lag")
  )]
  
  # 初始化
  ptr <- 1L  # ptr: pointer
  position <- 0L  # 当前持有的仓位，此处只有三个取值：{-1L, 0L, 1L}
  stop_price <- NA_real_   # 当持有仓位时，记录移动止损价。没有仓位时为NA_real_
  closed_profit <- 0.0   # 已平仓利润（累计）
  position_profit <- 0.0   # 持仓浮动盈亏
  fee <- 0.0   # 手续费（累计）
  out <- list()  # 逐日账户状态，list of list, for循环每循环一次，后面append一个list
  trades <- list()  # 逐笔交易记录，list of list。
  
  bar <- function(w){   # eg. bar("close") returns close price of this bar
    cdt[[w]][ptr]
  }
  pre <- function(w){   # eg. pre("close") returns the previous close price
    cdt[[w]][ptr - 1]
  }
  
  # 循环
  for(ptr in 1:nrow(cdt))   # ptr: pointer
  {
    # PART 0. 数据准备
    high <- bar("high")
    low <- bar("low")
    sig_long <- bar("high") > bar("N_high")
    sig_short <- bar("low") < bar("N_low")
    
    if (is.na(sig_short) | is.na(sig_long)) next  # 跳过前N个
    
    # PART 1. 检查止损，更新止损点
    
    if (position != 0L) {  # 如果持有仓位。。。
      stopifnot(!is.na(stop_price)) # stop_price不能是缺失值, 否则程序应停止报错
      
      stop_long <- position == 1L & low < stop_price  # bool
      stop_short <- position == -1L & high > stop_price  # bool
      
      if (stop_long | stop_short){
        # 平掉现有仓位
        leave_price <- stop_price - position * slippage  # long: - short: +
        closed_profit <- closed_profit + position * (leave_price - enter_price) * vm
        fee <- fee + leave_price * vm * fee.rate
        position_profit <- 0.0
        
        # 添加交易记录
        trade_out <- list(
          enter_date = enter_date,
          enter_price = enter_price,
          leave_date = bar("date"),
          leave_price = leave_price,
          side = position,
          commission = leave_price * vm * fee.rate + enter_price * vm * fee.rate
        ) 
        trades <- list.append(trades, trade_out)
        
        # 重置状态变量
        position <- 0L
        stop_price <- NA_real_
        enter_price <- NA_real_
        enter_date <- NA_real_
        rm(trade_out)
        
      } else {
        # 更新止损点
        if (position == 1L){
          stop_price <- max(stop_price, high * (1 - lossrate))
        } else if (position == -1L){
          stop_price <- min(stop_price, low * (1 + lossrate))
        } else {
          stop(102)
        }
      } # End if(stop_long | stop_short)
    } # End if(position == 0L)
    
    # PART 2. 处理开仓信号
    if (position == 0L) {
      # 情况1：没有任何仓位
      if (sig_long & !sig_short) {
        # 情况1.1：开多
        enter_price <- max(bar("N_high"), bar("open")) + slippage  # 入场价格
        enter_date <- bar("date")  # 记录入场时间
        stop_price <- enter_price * (1 - lossrate)  # 设好止损价
        position <- 1L
        fee <- fee + enter_price * vm * fee.rate
      } else if (sig_short & !sig_long) {
        # 情况1.2：开空
        enter_price <- min(bar("N_low"), bar("open")) - slippage # 入场价格
        enter_date <- bar("date")  # 记录入场时间
        stop_price <- enter_price * (1 + lossrate)  # 设好止损价
        position <- -1L
        fee <- fee + enter_price * vm * fee.rate
      } else if (sig_long & sig_short) {
        # 情况1.3：(极其少见)多空信号都出现了
        # you may add some message ...
      } else {
        # 情况1.4：既没有开多信号，也没有开空信号。
        # pass
      }
      
    } else if (position == 1L) {
      # 情况2：持有多仓
      # 持有多仓的情况下出现了开空信号：平掉现有的仓位，再反向开仓
      # pass
    } else if (position == -1L){
      # 情况3：持有空仓 
      # 持有空仓的情况下出现了开多信号：平掉现有的仓位，再反向开仓
      # pass
    } else {
      stop(101)
    }
    
    # PART 3. 保存信息至out变量
    position_profit <- ifelse(position == 0L, 
                              0.0, 
                              position * (bar("close") - enter_price) * vm
    ) # 计算持仓浮动盈亏
    bar_out <- list(
      date = bar("date"),
      position = position,
      closed_profit = closed_profit,
      position_profit = position_profit,
      close = bar("close"), 
      market_value = bar("close") * vm
    )
    out <- list.append(out, bar_out)
  }
  out_dt <- list.stack(out, data.table = TRUE)
  out_dt[, net_profit := closed_profit + position_profit - fee]
  
  rst <- data.table(
    N = N,
    lossrate = lossrate,
    final_profit = out_dt[.N, net_profit]
  )
  return(rst) # 也可以返回更详细的信息，做更进一步的分析。
}