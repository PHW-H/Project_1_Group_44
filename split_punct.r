setwd("C:/Users/pancr/OneDrive/Documents/R/Porject_1_Group_44")
#setwd("C:/Users/Tutku/Documents/2021-1/statistical_programming/Project_1_Group_44")
a <- scan("1581-0.txt",what="character",skip=156)
n <- length(a)
a <- a[-((n-2909):n)] ## strip license


###split vector a such that each punctuation mark and word is a different element


# find words containting
punctuation_marks <- c(",",";","!",":","\\?","\\.")

split_punct <-function (a){
for(i in 1:6) {# find and seperate the 6 different characters one by one
    n <- length(a)
    c <- grep(punctuation_marks[i],a) #find all locations of the ith punctuation mark
    lc <- length(c)

    if (lc>0){
      # this makes sure only an attempt to sperate word from punctuation marks is done 
      # when the text contains these punctuations marks
        
        #create empty string able to contain all of the string after the speration.
        ns <- rep("",2*lc+n)
        
        # determine the location of split words
        # three places are reserved for every interpunction mark
        # one for the text connected to the right and left of the punctuations mark
        # and one for the puncutation mark it self
        rcl <- c+2*(1:lc)
        ccl <- rcl-1
        lcl <- rcl-2
    
        # split words with a punctuation mark in three
        wlr <- strsplit(a[c], punctuation_marks[i])

        # create an empty string right of the punctuation mark it it does not exist
        # so every word with an interpunction is split in the same format
        for (val in 1:lc) {
            if (length(wlr[[val]])<2) {
                wlr[[val]] <- c(wlr[[val]],"")
                }}

        # make a matrix containing the text on the left and right of the interpunction 
        wrl <- matrix(unlist(wlr), ncol=2, byrow=TRUE)

        # paste the interpunction marks used to split the words in the text at their propper locatoin
        # to avoid the placement of "//" in th text ? and . have to be placed in a different way
        # to do so the if statemetn is used
        if (i==5){
            ns[ccl] <- "?"} 
            else if (i==6){
                ns[ccl] <- "."}
                else{
                    ns[ccl] <- punctuation_marks[i]}
        
        # paste the word left of the interpunction marks in the propper location 
        ns[lcl] <- wrl[,1]
        # paste the word right of the interpunction marks in the propper location 
        ns[rcl] <- wrl[,2]

        # nwl contains all locations in the text reseved for words split by interpunction marks and interpunctions words
        nwl <- c(rcl,ccl,lcl) 
        # past all other words in the empty string
        ns[-nwl] <- a[-c]
        # save the new string of words to a
        a <- ns

        # reset variables needed for next next itteration
        ##### i think this can be deleted #####
        rm(wrl)
        rm(wlr)
        }}
# eliminate all empty entries in string a
a <- a[a != ""]
return(a)}

a <- split_punct(a)


###create a vector b which includes the most common ~1000 words occurring in vector a


#lower capital letters in words
a_low <- tolower(a) 
#retrieve unique words in a
unique_words <- unique(a_low) 
#create a vector length of a which indicates the word's index in unique_words
index_vector <- match(a_low,unique_words) 
#create a vector length of b where each value corresponds to the frequency of the word with the same index in b
freq <- tabulate(index_vector) 

#initialize the threshold value to retain 1000 words
th <- 1
#initialize the number of common words with the given threshold value
ncw <- length(unique_words) 
#set value to 1000 as requested in the Practical 1 document
desired_word_count <- 1000

#a loop searching for a lower bound (threshold) on word frequencies which will obtain desired number of common words
#ends up with 2 values that approaches to the desired word count
#one value will be greater than desired_word_count stored as p_ncw (previously calculated number of common words)
#the other one will be less than desired_word_count stored as ncw
while (ncw >= desired_word_count) {
  p_th <- th
  th <- th + 1
  p_ncw <- ncw
  ncw <- sum(freq >= th)
}

#decides which value is closer to the desired word count and assigns threshold and m variables accordingly
#if both values are equally distant to the desired word count favors the smaller value
#e.g. p_ncw=1005 and p_th=90, and ncw_995 and th=91 where desired_word_count is 1000, it will choose the former.
if (desired_word_count - ncw < p_ncw - desired_word_count) {
  m <- ncw
  threshold <- th
} else {
  m <- p_ncw
  threshold <- p_th
}

#create a vector b such that it includes the words which occurred more than or equal to the threshold value 
b <- unique_words[which(freq >= threshold)]


###create matrix A such that A(i,j) is the estimated probability of word j coming after word i


#find index values of elements in a according to b, if not exists in b assigns value NA
a_index <- match(a_low, b)
#create a two-column matrix where the first column is transpose of a_index vector except the last element
#the second column is the transpose of a_index vector except the first element
column_matrix <- cbind(a_index[-length(a_index)],a_index[-1]) 
#find the rows where both values are a number, i.e where there is no NA value in the row
#these rows shows the common word pairs
pair_index <- which(!is.na(rowSums(column_matrix)))
#create word_pairs matrix excluding rows with NA values
word_pairs <- column_matrix[pair_index,]

#create an A matrix m by m where m is the number of commond words i.e. length(b)
A <- matrix(0,m,m) 
#fill A(i,j) matrix such that each A(i,j) value is the number of times the jth common word follows ith common word
#do this by looping over each row of word_pairs and adding 1 to A(i,j)
#where i=the first element of the row and j=the second element of the row
for (count in 1:nrow(word_pairs)){
  i <- word_pairs[count,1]
  j <- word_pairs[count,2]
  A[i,j] <- A[i,j]+1
}

#standardize each row of A by dividing each value by the row sum
A <- t(apply(A, 1, function(x)(x/sum(x)))) 
#there might be some rows whose row sum is 0
#this means none of the common words follows the word corresponding to the row, dividing values by zero results in NaN value
#in this case all of the common words are equally likely to occur after that word
#so replace NaN values with 1/length(b)
A <- gsub(NaN,1/m,A)
#previous function turns A into a vector, so turn A into matrix form again
A <- t(matrix(A, ncol=m, byrow=TRUE))


###update vector b such that common words that most often start with a capital letter in the main text 
###also starts with a common letter


#detect the words that include a capital letter
cap_bool <- a==a_low
#find these words' indexes
cap_index <- grep(FALSE,cap_bool)
#match words that include a capital letter with common word array b
unique_cap_index <- match(a_low[cap_index], b)
#create a vector which shows the frequency of a common word occurring with a capital letter
cap_freq <- tabulate(unique_cap_index)
#since some common words may never occur with a capital letter, fill the last part of the cap_freq vector with zeros
#until it comes to the length of common words vector b
cap_freq <- c(cap_freq, rep(0, length(b)-length(cap_freq)))
#find the frequency of common words in b
common_freq <- freq[freq >= threshold]
#find a common word's ratio of its frequency with a capital letter over its total frequency 
cap_prob <- cap_freq/common_freq
#make the first letter of the common word capital, if its ratio is greater than or equal to 0.5
substr(b[which(cap_prob>=0.5)], 1, 1) <- toupper(substr(b[which(cap_prob>=0.5)], 1, 1))


###form a 50-element text including punctuation marks based on the estimate probability matrix A


#randomly choose the starting words index out of m common words
prev_word_index <-sample(1:m,1)
#assign this value as the first element of end_text_index
end_text_index <- c(prev_word_index)

#create a 50-element vector called end_text_index 
#run the loop from 2 to 50 since the first element is already decided
#decide on the next element one by one according to the previous word's corresponding row in A matrix
#where each row in A matrix shows the estimated probabilities of each of the other common words following it
for (temp in 2:50){
  chosen_word_index <- sample(1:m,1,prob=A[prev_word_index,])
  end_text_index <- c(end_text_index, chosen_word_index)
  prev_word_index <- chosen_word_index
}

#print out the corresponding 50 words in common vector b 
cat(b[end_text_index])