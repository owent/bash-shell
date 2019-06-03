CREATE DATABASE redmine CHARACTER SET utf8;
CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';
