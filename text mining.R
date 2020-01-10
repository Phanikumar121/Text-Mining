wdset <- getwd()
#Set working directory
setwd(wdset)

require(caret)
require(tm)
require(data.table)

#Loading the dataset
mydata <- read.csv("yelp.csv")

#Selecting required columns for classification
mydata_1 <- mydata[,c(4,5,8,9,10)]

prop.table(table(mydata_1$stars))
mydata_1$type <- ifelse(mydata_1$stars>3,1,0)

mydata_1$stars <- factor(mydata_1$type)
#splitting data
require(caret)
set.seed(456)
my_split <- createDataPartition(mydata_1$stars,times = 1,p=0.8,list = FALSE)
train <- mydata_1[my_split,]
test <- mydata_1[-my_split,]

#CHECKING PROPORTIONS
prop.table(table(train$type))
prop.table(table(test$type))

library(tm)
docs <- VCorpus(VectorSource(train$text))
summary(docs)

# Clean corpus
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeNumbers)
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, stripWhitespace)
docs <- tm_map(docs, stemDocument, language = "english")

#Create dtm with TF-IDF
dtm <- DocumentTermMatrix(docs,control = list(weighting = function(x) weightTfIdf(x, normalize = FALSE)))
inspect(dtm)

#remove sparse
new_docterm_corpus <- removeSparseTerms(dtm,sparse = 0.97)
cols <- colSums(as.matrix(new_docterm_corpus))

library(data.table)
doc_feature <- data.table(name=attributes(cols)$names,count=cols)

processed_data <- as.data.table(as.matrix(new_docterm_corpus))
train1 <- cbind(data.table(type=train$type,Cool=train$cool,useful=train$useful,
                           funny=train$funny,processed_data))

#data partitiom
set.seed(789)
index1 <- createDataPartition(train1$type, times = 1,p = 0.7, list = FALSE)
train2=train1[index1,]
test2=train1[-index1,]

#model building
require(nnet)
mnominal_logmodel_categ <- nnet::multinom(type ~ ., data=train2)
saveRDS(mnominal_logmodel_categ,file = 'yelp_rating_logistic_model.rda')

rate_model <- readRDS("c:/Users/PHANI KUMAR/Desktop/6. TEXT MINING - CLASSIFICATION/To submit/yelp_rating_logistic_model.rda")

#Predicting on the test data
final_predict <- predict(rate_model,test2,type = 'class')

#accuracy for training
training_accuracy_pred <- table(predict(rate_model),train2$type)
train_acc <- sum(diag(training_accuracy_pred))/sum(training_accuracy_pred)  
print(train_acc)

#accuracy for testing.
testing_accuracy_pred <- table(final_predict,test2$type)
test_acc <- sum(diag(testing_accuracy_pred))/sum(testing_accuracy_pred)  
print(test_acc)

