# Gyazz - 手軽で強力なWiki

## 特徴

* Gyazz.comで運用しているものです
* 複数人が同時に編集してもそれなりにマージします

## インストール

* 必要なrubygemをインストール

        % gem install bundler
        % bundle install

* データ格納ディレクトリをつくる
* 環境にあわせて lib/config_template.rb から lib/config.rb をつくる

## 起動

    % bundle exec rackup config.ru -p 3000

=> <http://localhost:3000>
