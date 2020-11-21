# docker-compose + Rails6 + MySQL8.0

## シェルによる手順
- `git clone`したときに置いている、Dockerfileとdocker-compose.ymlは消してOK

```shell
# e.g) /bin/bash /path/to/init.sh -p portfolio -r password
$ /bin/bash init.sh -p {project_name} -r {root_password}
```

## 手作業の手順
### 1. Dockefileを元にしてdocker-compose.ymlで新たなコンテナイメージを作る
`docker-compose build` の実行
### 2. railsのWebサーバーコンテナとMySQLのDBサーバーコンテナを作る
1. `docker-compose up -d` の実行
2. `docker ps -a` の実行 で **STATUS**が**Up**になっていることを確認する
```sh
# 実行例
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS                  PORTS                               NAMES
2cd4872e0928        rails_sample_web       "irb"                    16 minutes ago      Up 16 minutes           0.0.0.0:3000->3000/tcp              rails_web
d3922d633a50        mysql:8.0              "docker-entrypoint.s…"   16 minutes ago      Up 16 minutes           0.0.0.0:3306->3306/tcp, 33060/tcp   rails_mysql
```
#### 補足
`docker-compose logs`で、
`webサーバーコンテナ`（以下、**Webコンテナ**もしくは、**rails_web**）, 
DBサーバーコンテナ（以下、**DBコンテナ**もしくは、**rails_mysql**）が
正常に起動できているか等の確認ができる

### 3. Webサーバーに入る
`docker exec -it rails_web /bin/bash` あるいは docker-compose.ymlがあるディレクトリで`docker-compose exec web /bin/bash` の実行で、
**rails_web**というコンテナ名のサーバーに入る

### 4. Railsチュートリアルにしたがって、新しいプロジェクトを作る
ここでは、[Railsガイト/Railsをはじめよう](https://railsguides.jp/getting_started.html) にしたがって作るものとする。

以下は、**Railsガイト/Railsをはじめよう** の **3.1 Railsのインストール** にしたがった一例

#### Rubyのバージョン確認
```
root@2cd4872e0928:/usr/src# ruby -v

=> ruby 2.7.0p0 (2019-12-25 revision 647ee6f091) [x86_64-linux]
```
- 2020.2現在最新の公式Rubyイメージ（ruby:2.7.0）をDockerfileで定義している

#### （SQLiteのバージョン確認（MySQLを使用していくので今後インストールの必要もなし）)
```
root@2cd4872e0928:/usr/src# sqlite3 --version

=> bash: sqlite3: command not found
```
- DockerのRubyイメージを使っているため、当然インストールされていない
- 今後SQLiteを使うこともないので、インストールの必要はない

#### (Gemによるrailsのインストール)
```
root@2cd4872e0928:/usr/src# gem install rails

=> Successfully installed rails-6.0.2.1
   1 gem installed
```
- オプションなしだと、最新のRailsがインストールされる（2020.2現在、rails-6.0.2.1）
- バージョンを保つ目的でDockefile内で以下を定義している
- 事前にその定義の実行によって作られた環境であるため、改めて`gem install rails`をここで実行しなくてよい

```Docker
# Dockerfile
（抜粋）
RUN gem install rails --version="~>6.0.0"
```

##### 補足
- rails --versionでRailsのバージョンは調べられる
```
root@a19247e0a147:/usr/src# rails --version

=> Rails 6.0.2.1
```

#### プロジェクトの作成

```
root@2cd4872e0928:/usr/src# rails new {project_name}

ex)
root@2cd4872e0928:/usr/src# rails new blog とか
root@2cd4872e0928:/usr/src# rails new portfolio など
```
- ただし、初期状態からMySQLを使っていくので、オプションをつける
- rails newコマンドを以下のオプションつきで実行

```
root@2cd4872e0928:/usr/src# rails new {project_name} --database=mysql
```
- **--database=mysql**：
  - 取り扱うDBをMySQLにする
  - オプションなしの場合、SQLiteを使うものとしてプロジェクトが作られる
- 他オプションについては、[参考 Railsドキュメント/アプリケーションの作成](https://railsdoc.com/rails) を参照

#### データベースの設定
- VSCode等のエディタ等で見ると、Webコンテナ内で`rails new` して作成したファイルが、{project_name}のフォルダ名で外部にも作成されている
- {project_name}/config/database.ymlをVSCode等のエディタ等で開く
- **database.yml**の**password**と**host**を以下のように修正

```yaml
  # before(rails newによる生成直後)
  password:
  host: localhost

  # after
  password: root
  host: db
```
- なぜ修正するのか？
  - **password** ： 後の手順で、DBを作成するがその時のrootユーザーのパスワードが必要
  - **host** ： Dockerで作ったMySQLとのDBコンテナとWebコンテナが通信する必要があるため、docker-compose.ymlのservice名「db」で指定する

#### データベースを作成する
- `rails db:create`でDBが作成される

```
root@2cd4872e0928:/usr/src/{project_name}# rails db:create

=> /usr/local/bundle/gems/actionpack-6.0.2.1/lib/action_dispatch/middleware/stack.rb:37: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
   /usr/local/bundle/gems/actionpack-6.0.2.1/lib/action_dispatch/middleware/static.rb:110: warning: The called method `initialize' is defined here
   Created database '{project_name}_development'
   Created database '{project_name}_test'
```

##### 補足
- DBコンテナに入って、DBが作成されているか確認する

1. まず、Webコンテナから出る
```
root@2cd4872e0928:/usr/src# exit
```
2. DBコンテナに入る
```
$ docker exec -it rails_mysql /bin/bash
```
3. MySQLのログインコマンドでMySQLとの対話シェルを起動
```
root@58a6d02a3467:/# mysql -u root -p

=> Enter password:
   とパスワードを求められるので`-u`で指定したrootユーザーのパスワードを入力する

=>  Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 15
    Server version: 8.0.19 MySQL Community Server - GPL
    
    Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    mysql>
```
4. データベースの一覧を見る
```
mysql>show databases;

=> # rails new の{project_name}を portfolio にしたので
   # portfolio_development と portfolio_test ができている
+-----------------------+
| Database              |
+-----------------------+
| information_schema    |
| mysql                 |
| performance_schema    |
| portfolio_development |
| portfolio_test        |
| sys                   |
+-----------------------+
6 rows in set (0.01 sec)
```
5. MySQLとの対話シェルをやめる
```
mysql>exit;
```
6. DBコンテナから出る
```
root@58a6d02a3467:/# exit
```
7. （Webコンテナに入る）
```
$ docker exec -it rails_web /bin/bash
```

### 5. RailsのアプリサーバーをWebコンテナの上で起動する
1. `rails new`で作ったプロジェクトのフォルダ内（以下、「ディレクトリ」または「プロジェクト配下」）に移動

```
# Webコンテナにいる状態で
root@a19247e0a147:/usr/src# cd {project_name}

ex)
root@a19247e0a147:/usr/src# cd portfolio
```
2. `rails server`により、Webコンテナ内でアプリサーバーを起動
- [参考 Railsドキュメント/ローカルでサーバを起動](https://railsdoc.com/rails#rails_server)
```
root@a19247e0a147:/usr/src/portfolio# rails server（rails sでもよい）
```

3. サーバーの起動を待ち、ブラウザから初期画面にアクセスする
- Listening on tcp:0.0.0.0:3000が表示されるまで待つ
- `http://localhost:3000`でブラウザからアクセスする
- Yay! You’re on Rails! を確認する
- Macの場合「control + c」でアプリサーバーを止める

```
=> Booting Puma
=> Rails 6.0.2.1 application starting in development 
=> Run `rails server --help` for more startup options
/usr/local/bundle/gems/actionpack-6.0.2.1/lib/action_dispatch/middleware/stack.rb:37: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
/usr/local/bundle/gems/actionpack-6.0.2.1/lib/action_dispatch/middleware/static.rb:110: warning: The called method `initialize' is defined here
Puma starting in single mode...
* Version 4.3.1 (ruby 2.7.0-p0), codename: Mysterious Traveller
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
```
