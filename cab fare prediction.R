rm(list=ls())
setwd("D:/R and PYTHON files/data set/project 3")
getwd()

# loading all required librares.
install.packages (c("ggplot2", "corrgram", "DMwR", "caret", "randomForest", "unbalanced", "C50", "dummies", "e1071", "Information",
                    "MASS", "rpart", "gbm", "ROSE", 'sampling', 'DataCombine', 'inTrees'))

# loading the data
train=read.csv("train_cab.csv",header=TRUE)
test=read.csv("test.csv",header=TRUE)


# exploring the data.
str(train)
str(test)
summary(train)
summary(test)
head(train,5) 
head(train,5)

# converting the features in the required data types.
train$fare_amount = as.numeric(as.character(train$fare_amount))
train$passenger_count=round(train$passenger_count)

########### data cleaning  #############
# fare amount cannot be less than one 
# considring fare amount 453 as max and removing all the fare amount greater than 453, as chances are
# very less of fare amount having 4000 and 5000 ...etc
train[which(train$fare_amount < 1 ),]
nrow(train[which(train$fare_amount < 1 ),]) # to show the count i.e.,5
train = train[-which(train$fare_amount < 1 ),]  # removing those values.
train[which(train$fare_amount>453),]
nrow(train[which(train$fare_amount >453 ),]) # to show the count i.e., 2
train = train[-which(train$fare_amount >453 ),]  # removing those values.
# passenger count cannot be Zero
# even if we consider suv max seat is 6, so removing passenger count greater than 6.
train[which(train$passenger_count < 1 ),]
nrow(train[which(train$passenger_count < 1 ),]) # to show count, that is 58
train=train[-which(train$passenger_count < 1 ),] # removing the values
train[which(train$passenger_count >6 ),]
nrow(train[which(train$passenger_count >6 ),]) # to show count, that is 20
train=train[-which(train$passenger_count >6 ),] # removing the values
# Latitudes range from -90 to 90.Longitudes range from -180 to 180.
# Removing which does not satisfy these ranges.
print(paste('pickup_longitude above 180=',nrow(train[which(train$pickup_longitude >180 ),])))
print(paste('pickup_longitude above -180=',nrow(train[which(train$pickup_longitude < -180 ),])))
print(paste('pickup_latitude above 90=',nrow(train[which(train$pickup_latitude > 90 ),])))
print(paste('pickup_latitude above -90=',nrow(train[which(train$pickup_latitude < -90 ),])))
print(paste('dropoff_longitude above 180=',nrow(train[which(train$dropoff_longitude > 180 ),])))
print(paste('dropoff_longitude above -180=',nrow(train[which(train$dropoff_longitude < -180 ),])))
print(paste('dropoff_latitude above -90=',nrow(train[which(train$dropoff_latitude < -90 ),])))
print(paste('dropoff_latitude above 90=',nrow(train[which(train$dropoff_latitude > 90 ),])))
train = train[-which(train$pickup_latitude > 90),] # removing one data point
# Also we will see if there are any values equal to 0.
nrow(train[which(train$pickup_longitude == 0 ),])
nrow(train[which(train$pickup_latitude == 0 ),])
nrow(train[which(train$dropoff_longitude == 0 ),])
nrow(train[which(train$pickup_latitude == 0 ),])
# removing those data points.
train=train[-which(train$pickup_longitude == 0 ),]
train=train[-which(train$dropoff_longitude == 0),]

# checking for missing values.
sum(is.na(train))
sum(is.na(test))
train=na.omit(train) # we have removed the missing values...as they are less,,..likely 50 to 60 missing values.
sum(is.na(train))  

# deriving the new features using pickup_datetime and coordinated provided.
# new features will be year,month,day_of_week,hour
# Convert pickup_datetime from factor to date time
train$pickup_datetime=as.Date(train$pickup_datetime)
pickup_time = strptime(train$pickup_datetime,format='%Y-%m-%d %H:%M:%S UTC')
train$date = as.integer(format(train$pickup_date,"%d"))# Monday = 1
train$mnth = as.integer(format(train$pickup_date,"%m"))
train$yr = as.integer(format(train$pickup_date,"%Y"))
#train$min = as.integer(format(train$pickup_date,"%M"))
#train$day=as.integer(as.POSIXct(train$pickup_datetime),abbreviate=F)

# for test data set.
test$pickup_datetime=as.Date(test$pickup_datetime)
pickup_time = strptime(test$pickup_datetime,format='%Y-%m-%d %H:%M:%S UTC')
test$date = as.integer(format(test$pickup_date,"%d"))# Monday = 1
test$mnth = as.integer(format(test$pickup_date,"%m"))
test$yr = as.integer(format(test$pickup_date,"%Y"))
# outlier
#library(ggplot2)
#pl1 = ggplot(train,aes(x = factor(passenger_count),y = fare_amount))
#pl1 + geom_boxplot(outlier.colour="red", fill = "grey" ,outlier.shape=18,outlier.size=1, notch=FALSE)+ylim(0,100)

# deriving the new feature, distance from the given coordinates.
deg_to_rad = function(deg){
  (deg * pi) / 180
}
haversine = function(long1,lat1,long2,lat2){
  #long1rad = deg_to_rad(long1)
  phi1 = deg_to_rad(lat1)
  #long2rad = deg_to_rad(long2)
  phi2 = deg_to_rad(lat2)
  delphi = deg_to_rad(lat2 - lat1)
  dellamda = deg_to_rad(long2 - long1)
  
  a = sin(delphi/2) * sin(delphi/2) + cos(phi1) * cos(phi2) * 
    sin(dellamda/2) * sin(dellamda/2)
  
  c = 2 * atan2(sqrt(a),sqrt(1-a))
  R = 6371e3
  R * c / 1000 #1000 is used to convert to meters
}
train$distance = haversine(train$pickup_longitude,train$pickup_latitude,train$dropoff_longitude,train$dropoff_latitude)
test$distance = haversine(test$pickup_longitude,test$pickup_latitude,test$dropoff_longitude,test$dropoff_latitude)


# removing the features, which were used to create new features.
train = subset(train,select = -c(pickup_longitude,pickup_latitude,dropoff_longitude,dropoff_latitude,pickup_datetime))
test = subset(test,select = -c(pickup_longitude,pickup_latitude,dropoff_longitude,dropoff_latitude,pickup_datetime))
str(train)
summary(train)
nrow(train[which(train$distance ==0 ),])
nrow(test[which(test$distance==0 ),])
nrow(train[which(train$distance >130 ),]) # considering the distance 130 as max and considering rest as outlier.
nrow(test[which(test$distance >130 ),])
# removing the data points by considering the above conditions,
train=train[-which(train$distance ==0 ),]
train=train[-which(train$distance >130 ),]
test=test[-which(test$distance ==0 ),]

# feature selection
numeric_index = sapply(train,is.numeric) #selecting only numeric
numeric_data = train[,numeric_index]
cnames = colnames(numeric_data)

#Correlation analysis for numeric variables
library(corrgram)
corrgram(train[,numeric_index],upper.panel=panel.pie, main = "Correlation Plot")

#removing date
# pickup_weekdat has p value greater than 0.05 
train = subset(train,select=-date)
#remove from test set
test = subset(test,select=-date)


## feature scaling ##
library(car)
library(MASS)
qqPlot(train$fare_amount) # qqPlot, it has a x values derived from gaussian distribution, if data is distributed normally then the sorted data points should lie very close to the solid reference line 
truehist(train$fare_amount) # truehist() scales the counts to give an estimate of the probability density.
lines(density(train$fare_amount)) # lines() and density() functions to overlay a density plot on histogram

d=density(train$fare_amount)
plot(d,main="distribution")
polygon(d,col="green",border="red")

D=density(train$distance)
plot(D,main="distribution")
polygon(D,col="green",border="red")

A=density(test$distance)
plot(A,main="distribution")
polygon(A,col="black",border="red")

#Normalisation
# log transformation.
train$fare_amount=log1p(train$fare_amount)
test$distance=log1p(test$distance)
train$distance=log1p(train$distance)

# checking back features after transformation.
d=density(train$fare_amount)
plot(d,main="distribution")
polygon(d,col="green",border="red")
D=density(train$distance)
plot(D,main="distribution")
polygon(D,col="red",border="black")
A=density(test$distance)
plot(A,main="distribution")
polygon(A,col="black",border="red")




#print('fare_amount')
#train[,'fare_amount'] = (train[,'fare_amount'] - min(train[,'fare_amount']))/
 # (max(train[,'fare_amount'] - min(train[,'fare_amount'])))
#train[,'distance'] = (train[,'distance'] - min(train[,'distance']))/
 # (max(train[,'distance'] - min(train[,'distance'])))
#test[,'distance'] = (test[,'distance'] - min(test[,'distance']))/
 # (max(test[,'distance'] - min(test[,'distance'])))

###check multicollearity
 library(usdm)
 vif(train[,-1])
 vifcor(train[,-1], th = 0.9)
 #No variable from the 4 input variables has collinearity problem. 
 #The linear correlation coefficients ranges between: 
 #min correlation ( mnth ~ passenger_count ):  -0.001868147 
 #max correlation ( yr ~ mnth ):  -0.1091115 
 
# ---------- VIFs of the remained variables -------- 
#   Variables      VIF
# 1 passenger_count 1.000583
# 2            mnth 1.012072
# 3              yr 1.012184
# 4        distance 1.000681

 ## to make sure that we dont have any missing values
 sum(is.na(train))
 train=na.omit(train)
 
# model building
# preparing the data
set.seed(1200)
Train.index = sample(1:nrow(train), 0.9 * nrow(train))
Train = train[ Train.index,]
Test  = train[-Train.index,]
#head(Test[,2:5],5)
TestData=test
# linear regression
linear_model=lm(fare_amount~.,data=Train)
summary(linear_model)
predict_lm=predict(linear_model,Test[,2:5])
predict_test=predict(linear_model,TestData)

# decision tree regressor
library(rpart)
DT=rpart(fare_amount~.,data=Train,method="anova")
predictions_tree=predict(DT,Test[,2:5])
predictions_test=predict(DT,TestData)
summary(DT)

# random forest regressor
library(randomForest)
random_model = randomForest(fare_amount~ ., Train, importance = TRUE, ntree = 500)

#Extract rules fromn random forest
#transform rf /object to an inTrees' format
library(inTrees)
treeList = RF2List(random_model)  

#Extract rules
rules= extractRules(treeList, Train[,2:5])

#Visualize some rules
rules[1:2,]
#Make rules more readable:
readrules = presentRules(rules, colnames(Train))
readrules[1:2,]

#Predict test data using random forest model
RF_Predictions = predict(random_model, Test[,2:5])
RF_test=predict(random_model, TestData)

# saving the results in hard disk
#write(capture.output(summary(random_model)),"RF_summary.txt")

## accuracy check
#defining the function (to find the error percentage)
mape=function(av,pv){
  mean(abs((av-pv)/av))*100 #av=actual value and pv= predicted value
}
library(DMwR)
# linear regression model
mape(Test[,1],predict_lm)
# 7.8
regr.eval(Test[,1],predict_lm)
# mae        mse       rmse       mape 
#0.18035915 0.08013439 0.28308018 0.07892880 
# decision tree
mape(Test[,1],predictions_tree)
# 8.8
regr.eval(Test[,1],predictions_tree)
# mae        mse       rmse       mape 
#0.20133555 0.08520206 0.29189392 0.08854953 

# random_forest
mape(Test[,1],RF_Predictions)
# 9.8
regr.eval(Test[,1],RF_Predictions)
# mae        mse       rmse       mape 
#0.22070787 0.09726554 0.31187423 0.09823838 

