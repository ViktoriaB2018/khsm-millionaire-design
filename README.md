# Who wants to be a millionaire?

## Game for children from 12 to 159 years old
### Ruby on Rails course application from Good Programmer. In production, set up to work with Heroku.

* Ruby version 2.5.3
* Rails version 4.2.11
* Deploy Heroku - https://multimillionaire.herokuapp.com/

#### Before running

```
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
```

#### Run tests

```
rspec spec
```

#### For downloading text files with questions and answers from app/public/data

You need to make an admin from any user (for example with id = 1) in rails console:

```
rails c
User.find(1).toggle!(:is_admin)
```
Than you'll see button 'Залить новые вопросы' in mine page. Use it.
