---
layout: post
title: "Genpact Machine Learning Hackathon - 5th Place solution"
---

Here is my __5th place solution__ to the 
[Genpact Machine Learning Hackathon](https://datahack.analyticsvidhya.com/contest/genpact-machine-learning-hackathon/pvt_lb)
conducted by Analytics Vidhya in December 2018.

The full Python code is available on [my github repository](https://github.com/varunbpatil/ML-Hackathon/tree/master/Genpact_ML_Hackathon_Dec_2018).

<br/>

#### Problem Statement

The task in this ML hackathon was to predict the number of food orders for an
online food delivery business at each of their branches on a particular week in the future.


Solving such a problem is useful for planning just-in-time procurement of ingredients
so as to reduce wastage and costs.

<br/>

#### A look at the data

Here's the training data we were asked to work with.

| Column | Description |
| ------ | ----------- |
| `id` | Unique transaction id |
| `week` | Week number; training data had weeks 1 through 145 |
| `center_id` | Unique identifier for the branch of the online food delivery business |
| `meal_id` | Unique identifier for the meal |
| `checkout_price` | Price of the meal after discounts, coupons, etc |
| `base_price` | Base price of the meal |
| `emailer_for_promotion` | Boolean indicating whether the meal was promoted via email |
| `homepage_featured` | Boolean indicating whether the meal was featured on the website's homepage |
| `num_orders` | The target (or dependent) variable we were asked to predict |


<br/>

There was also the following information about the branch of the food delivery business.

| Column | Description |
| ------ | ----------- |
| `center_id` | Unique identifier for the branch of the online food delivery business |
| `city_code` | Unique identifier for the city in which the branch operates |
| `region_code` | Unique identifier for the region in which the branch operates |
| `center_type` | Categorical variable for the branch type |
| `op_area` | Operating area of the branch |


<br/>

Then, there was some information about the meal's themselves.

| Column | Description |
| ------ | ----------- |
| `meal_id` | Unique identifier for the meal |
| `category` | The meal category  |
| `cuisine` | The meal cuisine (categorical variable) |


<br/>

#### Machine Learning Model

I decided to use the [__LightGBM regressor__](https://lightgbm.readthedocs.io/en/latest/Python-API.html#lightgbm.LGBMRegressor) 
for this challenge since from my experience in such competitions, 
gradient boosted trees are very powerful and popular.


<br/>

#### Feature Engineering and Data Transformations

I decided to use most of the given features as it is apart from the following new features
I designed.

| Feature | Description |
| ------- | ---- |
| `week_sin` | Sine transform of the 'week' to capture cyclic dependency |
| `week_cos` | Cosine transform of the 'week' to capture cyclic dependency |
| `price_diff_percent` | Percentage difference between checkout_price and base_price |

<br/>
[Sine and cosine transform's](https://ianlondon.github.io/blog/encoding-cyclical-features-24hour-time/) 
are very frequently used to represent cyclic features like the 'week' in our case.
This is useful when you are trying to capture dependencies like increased demand during a particular
month every year due to a festival, for example.

The formula for the sine and cosine transform for the 'week' variable is as below:

```python
week_sin = np.sin(2 * np.pi * week / 52.143)
week_cos = np.cos(2 * np.pi * week / 52.143)
```

Ofcourse, I decided to keep the original 'week' feature as well to capture long-term dependency 
(for example, increase in demand over the years).

<br/>
I used [scikit-learn's label encoder](https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.LabelEncoder.html)
to encode categorical variables since that is how __LightGBM__ prefers it.

<br/>

#### Transforming the target variable

I used the __log transform__ (np.log1p()) on the target variable - `num_orders` - so that
it looked more like a gaussian distribution (bell-shaped curve). The original 'num_orders'
had values ranging from a few hunders to several thousands with a majority of the values
in the lower range.

Another reason for the log transformation of the target variable was that the metric for
the competition was RMSLE (root mean squared log error) which means after the log transformation
of the target variable, I could simply use the build-in "mse" or "rmse" metric of LightGBM.

<br/>

#### Hyperparameter tuning

I used [scikit-learn's Parameter Grid](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.ParameterGrid.html)
to systematically search through hyperparameter values for the LightGBM model.

The hyperparameters I tuned with this method are:

1. __colsample_bytree__ - Also called feature fraction, it is the fraction of features to consider while building a single gradient boosted tree. Reducing its value _reduces overfitting_ by considering fewer features while building each tree.
2. __min_child_samples__ - The number of samples in the leaf node of the tree.
3. __num_leaves__ - The number of leaf nodes. Higher the number, the more complex and deeper the tree is going to be making the model overfit.

<br/>

#### Choosing the cross-validation set

Since we are trying to predict the number of orders on a future date, it makes sense
to order the training data by the 'week' in ascending order and then pick samples
at the end of the list as our cross-validation set. For example, since we are given
training data for week's 1 through 145, we can consider data for week's 1 through 140
as our training data and week's 141 through 145 as our cross-validation data.

For this, I used [scikit-learn's train test split](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.train_test_split.html)
to split the given training data into a train and cross-validation set. 
Note that I explicitly set `shuffle=False` since we want the data to be ordered
by week and we want to take samples towards the end as our cross-validation set.

<br/>

#### Solution

The full Python code is available on [my github repository](https://github.com/varunbpatil/ML-Hackathon/tree/master/Genpact_ML_Hackathon_Dec_2018).

<br/>
__Read the training and test datasets.__


```python
df_train = pd.read_csv('train_GzS76OK/train.csv')
df_center_info = pd.read_csv('train_GzS76OK/fulfilment_center_info.csv')
df_meal_info = pd.read_csv('train_GzS76OK/meal_info.csv')
df_test = pd.read_csv('test_QoiMO9B.csv')
```

<br/>

__Merge with branch and meal information.__

```python
df_train = pd.merge(df_train, df_center_info,
                    how="left",
                    left_on='center_id',
                    right_on='center_id')

df_train = pd.merge(df_train, df_meal_info,
                    how='left',
                    left_on='meal_id',
                    right_on='meal_id')

df_test = pd.merge(df_test, df_center_info,
                   how="left",
                   left_on='center_id',
                   right_on='center_id')

df_test = pd.merge(df_test, df_meal_info,
                   how='left',
                   left_on='meal_id',
                   right_on='meal_id')
```

<br/>

__Feature engineering - Convert 'city_code' and 'region_code' into a single feature - 'city_region'.__

```python
df_train['city_region'] = \
        df_train['city_code'].astype('str') + '_' + \
        df_train['region_code'].astype('str')

df_test['city_region'] = \
        df_test['city_code'].astype('str') + '_' + \
        df_test['region_code'].astype('str')
```

<br/>

__Label encode categorical features (label encoded features will have suffix _encoded_).__

```python
label_encode_columns = ['center_id', 
                        'meal_id', 
                        'city_code', 
                        'region_code',
                        'city_region',
                        'center_type', 
                        'category', 
                        'cuisine']

le = preprocessing.LabelEncoder()

for col in label_encode_columns:
    le.fit(df_train[col])
    df_train[col + '_encoded'] = le.transform(df_train[col])
    df_test[col + '_encoded'] = le.transform(df_test[col])
```

<br/>

__Feature engineering - Sine and Cosine transform for 'week' - Capture cyclic dependency.__

```python
df_train['week_sin'] = np.sin(2 * np.pi * df_train['week'] / 52.143)
df_train['week_cos'] = np.cos(2 * np.pi * df_train['week'] / 52.143)

df_test['week_sin'] = np.sin(2 * np.pi * df_test['week'] / 52.143)
df_test['week_cos'] = np.cos(2 * np.pi * df_test['week'] / 52.143)
```

<br/>

__Feature engineering - Price difference percentage.__

```python
df_train['price_diff_percent'] = \
        (df_train['base_price'] - df_train['checkout_price']) / df_train['base_price']

df_test['price_diff_percent'] = \
        (df_test['base_price'] - df_test['checkout_price']) / df_test['base_price']
```

<br/>

__Feature engineering - Convert the ad campaign features - 'emailer_for_promotion' and 'homepage_featured' into a single feature.__

Both these features were originally boolean (0 and 1). 
So, adding them up to create a new feature does not require label encoding.

```python
df_train['email_plus_homepage'] = df_train['emailer_for_promotion'] + df_train['homepage_featured']

df_test['email_plus_homepage'] = df_test['emailer_for_promotion'] + df_test['homepage_featured']
```

<br/>

__Prepare a list of features to train on. Split them into categorical and numerical features.__

```python
columns_to_train = ['week',
                    'week_sin',
                    'week_cos',
                    'checkout_price',
                    'base_price',
                    'price_diff_percent',
                    'email_plus_homepage',
                    'city_region_encoded',
                    'center_type_encoded',
                    'op_area',
                    'category_encoded',
                    'cuisine_encoded',
                    'center_id_encoded',
                    'meal_id_encoded']

categorical_columns = ['email_plus_homepage',
                       'city_region_encoded',
                       'center_type_encoded',
                       'category_encoded',
                       'cuisine_encoded',
                       'center_id_encoded',
                       'meal_id_encoded']

numerical_columns = [col for col in columns_to_train if col not in categorical_columns]
```

<br/>

__Log transform the target variable - num_orders.__

```python
df_train['num_orders_log1p'] = np.log1p(df_train['num_orders'])
```

I used the `np.log1p()` instead of `np.log()` because it is more numerically stable (i.e, log(0) is not defined).

<br/>

__Train + Cross-validation split.__

The original dataset was already sorted by week number. I just had to pick the samples towards the end
as the cross validation set. This corresponds to week numbers 141 through 145. Since we're trying
to predict orders at a future date, __random shuffling of the dataset before split does not make sense__
and hence the `shuffle=False`.

```python
X = df_train[categorical_columns + numerical_columns]
y = df_train['num_orders_log1p']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.02, shuffle=False)
```

<br/>

__Hyperparameter grid search.__

```python
scores = []
params = []

param_grid = {'num_leaves': [31, 127, 255],
              'min_child_samples': [5, 10, 30],
              'colsample_bytree': [0.4, 0.6, 0.8]}

for i, g in enumerate(ParameterGrid(param_grid)):
    print("param grid {}/{}".format(i, len(ParameterGrid(param_grid)) - 1))
    pprint.pprint(g)
    
    estimator = LGBMRegressor(learning_rate=0.003,
                              n_estimators=10000,
                              silent=False,
                              **g)
    
    fit_params = {'feature_name': categorical_columns + numerical_columns,
                  'categorical_feature': categorical_columns,
                  'eval_set': [(X_train, y_train), (X_test, y_test)]}

    estimator.fit(X_train, y_train, **fit_params)
    
    scores.append(estimator.best_score_['valid_1']['l2'])
    params.append(g)


print("Best score = {}".format(np.min(scores)))
print("Best params =")
print(params[np.argmin(scores)])
```

__LightGBM is able to natively work with categorical features__ by specifying the `categorical_feature`
parameter to the `fit` method. Also, I've stayed with the __default evaluation metric for LightGBM regressor
which is L2 (or MSE or Mean Squared Error).__


<br/>

__Training the final LightGBM regression model on the entire dataset.__

I used a method called `early stopping` to reduce overfitting. As a result, I cannot
use the entire dataset for training. I will have to keep aside a test set for the purpose
of early stopping. 

The following model was trained using the best hyperparameters obtained
by the parameter grid search step above.

```python
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.02, shuffle=False)

g = {'colsample_bytree': 0.4,
     'min_child_samples': 5,
     'num_leaves': 255}

estimator = LGBMRegressor(learning_rate=0.003,
                          n_estimators=40000,
                          silent=False,
                          **g)

fit_params = {'early_stopping_rounds': 1000,
              'feature_name': categorical_columns + numerical_columns,
              'categorical_feature': categorical_columns,
              'eval_set': [(X_train, y_train), (X_test, y_test)]}

estimator.fit(X_train, y_train, **fit_params)
```

<br/>

__Get predictions on the test data and prepare a submission file for the contest.__

Since the target variable was log transformed using `np.log1p()`, the predicted num_orders
will have to be inverse transformed using `np.expm1()`.

```python
X = df_test[categorical_columns + numerical_columns]

pred = estimator.predict(X)
pred = np.expm1(pred)

submission_df = df_test.copy()
submission_df['num_orders'] = pred
submission_df = submission_df[['id', 'num_orders']]
submission_df.to_csv('submission.csv', index=False)
```