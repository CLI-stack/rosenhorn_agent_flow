import ftplib 
 
ftp = ftplib.FTP("10.65.133.133") 
ftp.login("ftp_sever|ftp_sever", "Qw@37589016") 
 
ftp.cwd("/") 
files = ftp.nlst() 
for file in files: 
    print(file) 
 
filename = "tasksMail.csv" 
with open(filename, "wb") as f: 
    ftp.retrbinary("RETR " + filename, f.write) 

""" 
filename = "example.txt" 
with open(filename, "rb") as f: 
    ftp.storbinary("STOR " + filename, f) 
 """
ftp.quit() 
