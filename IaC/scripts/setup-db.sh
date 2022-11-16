docker run -p 80:80 dig0w/letscode_fe
docker run -e MYSQL_DB_HOST=jdbc:mysql://$MYSQL_DB_HOST:3306 -e MYSQL_DB_USER=letscode -e MYSQL_DB_PASS=7ROtBB44*0XN dig0w/letscode_be

curl -X POST localhost:8080/api/usuarios -H 'Content-Type: application/json' -d '{"username":"diego","password":"password"}'

mysql -u letscode -h terraform-20221013191211824500000001.cffv94ggjzlm.us-east-1.rds.amazonaws.com -p 7ROtBB44*0XN

CREATE DATABASE letscode;