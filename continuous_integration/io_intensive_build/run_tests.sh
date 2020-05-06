url=https://www.flamingspork.com/projects/libeatmydata/libeatmydata-105.tar.gz
wget -qO- $url | tar -zxf - && cd libeatmydata-105
./configure --prefix=/usr
make
sudo make install
