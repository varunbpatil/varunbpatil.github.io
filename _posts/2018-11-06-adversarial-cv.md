---
layout: post
title: "Adversarial cross-validation for train and test sets from different distributions"
---

Recently, I was working on the [GStore customer revenue prediction kaggle competition](https://www.kaggle.com/c/ga-customer-revenue-prediction/leaderboard).
I noticed early on that the CV score I was getting from a stratified k-fold CV was not translating well to the leaderboard score which led me to suspect
that the test set distribution wasn't the same as the training set distribution which is usually the case for time series data like this one.

Then, I found out about __adversarial cross-validation__. The idea behind adversarial cross-validation is simple - You find out examples from your training set
that look a lot like the test set and use these examples as your cross-validation set.

How do you pick examples from the training set that resemble the test set, you ask ? Well, the procedure is very simple.

1. Combine the train and test sets into one large training set and randomly shuffle them.
   Of course, you'll leave out the target variable from the training set (which isn't available in the test set).

2. Set a new target variable for your combined train + test set. Set the target variable to '1' if it came from the original test set,
   '0' if it came from the original training set.

3. Train a classifier on your combined train + test set. Since the training and test sets come from different distributions,
   hopefully, your classifier will be able to distinguish between them easily, and thus, do a good job of classification.

4. Using the classifier trained in step 3, predict the target variables for your original training set. Your cross-validation set should then include
   examples from the original training set for which your classifier predicted '1' with high confidence (i.e, your classifier thinks the example came from
   the original test set even though it is part of the original training set).


As you might have gathered, the term `adversarial` comes from pitting the original training and test sets against each other.


The following is an example of how you might go about performing adversarial cross-validation in Python
using the data from the GStore kaggle competition mentioned above.

NOTE: Some obvious parts of the code have been left out to focus specifically on the adversarial cross-validation procedure.


<br/><br/>
__Load the original training and test sets.__


```python
df_train = pd.read_csv(...)
df_test = pd.read_csv(...)
```

<br/><br/>
__Set the new target variables.__

__'1' if the data is from the original test set.__
__'0' if the data is from the original training set.__


```python
df_train['TARGET'] = 0
df_test['TARGET'] = 1
```

<br/><br/>
__Concatenate the original training and test sets.__

'categorical_cols' and 'numeric_cols' below are the categorical and numeric features (excluding the original target variable).


```python
df = pd.concat([df_train[categorical_cols + numeric_cols + ['TARGET']], df_test[categorical_cols + numeric_cols + ['TARGET']]])
```

<br/><br/>
__Shuffle the combined train + test set and train a classifier on it.__

Here, I'm training a LGBM classifier.


```python
X, y = df.drop(columns=['TARGET']).values, df['TARGET'].values
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

g = {'colsample_bytree': 0.3, 'min_child_samples': 5, 'num_leaves': 31}

lgbm_classifier = lgb.LGBMClassifier(learning_rate=0.01,
                                     n_estimators=2000, 
                                     silent=False,
                                     importance_type="gain",
                                     **g)

fit_params = {'early_stopping_rounds': 100,
              'feature_name': categorical_cols + numeric_cols,
              'categorical_feature': categorical_cols,
              'eval_metric': "auc",
              'eval_set': [(X_test, y_test)]}

lgbm_classifier.fit(X_train, y_train, **fit_params)
```

<br/><br/>
__Get predictions on the original training set.__

We will use the predict_proba() method to get the confidence measure instead of a simple classification.


```python
X_pred = df_train[categorical_cols + numeric_cols].values
df_train['TARGET_pred'] = lgbm_classifier.predict(X_pred)
df_train['TARGET_pred_proba'] = lgbm_classifier.predict_proba(X_pred)[:, 1]
```

<br/><br/>
__Pick examples from the original training set that the classifier thinks came from the test set.__


```python
tmp_df = df_train[df_train['TARGET_pred'] == 1]
```

<br/><br/>
__Sort examples from the original training set by the confidence with which the classifier thinks they came from the test set.__


```python
tmp_df = tmp_df.sort_values('TARGET_pred_prob', ascending=False)
```

<br/><br/>
__Pick the top 'n' (ex: 10000) examples (which have a high predicted probability of belonging to the test set) as your cross validation set.__


```python
cross_val = tmp_df.head(10000)
```
