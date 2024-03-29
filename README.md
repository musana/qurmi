# post-exploits

## qurmi post exploit modül

Pentest yaparken hem zamandan kazanç hem de gözden kaçırma durumlarını engellemek adına
kullanılan otomatize toollar pentesterlar için büyük öneme sahiptir. Belirli durumlar için yazılmış çok
çeşitli toollar bulmak mümkündür. Ancak bazı durumlarda kendi toolumuzu yazma ihtiyacı
doğabilmektedir. Qurmi aracı da bu ihtiyaçlar neticesinde ruby ile geliştirilmiş bir post exploit
tooludur ve metasploit bünyesinde çalışmaktadır.

Mevcut meterpreter oturumları üzerinde topluca işlem yapmaya imkan tanımaktadır. [psexec_scanner](https://github.com/darkoperator/Meterpreter-Scripts/blob/master/auxiliary/scanner/smb/psexec_scanner.rb) modülü ile beraber kullanılınca daha etkili olabilmektedir. Psexec_scanner, domain admin'in kimlik bilgilerini kullanılarak smb servisi açık olan diğer makinelerden meterpreter oturumu almak için kullanılmaktadır.

Modüle ait ilgili video; 

[![qurmi](https://github.com/musana/post-exploits/blob/master/pictures/1.png)](https://www.youtube.com/watch?v=OTSdRc0ZTeA&feature=youtu.be)

### Komutlar
* **show_sessions** Aktif meterpreter oturumlarını listelemek için.
* **set_targets** Aktif meterpreter oturumlarından hedef listesine oturum eklemek için. 3 farklı formatta parametre alır.
  1. **set_targets all :** Mevcut bütün oturumları target listesine ekler.
  2. **set_targets 1-7 :** 1 ile 7(dahil) aralığını target listesine ekler. (İlgili aralıkta aktif olmayan oturumları pas geçer.)
  3. **set_targets 1,3,6 :** Sadece 1,3 ve 6 id değerine sahip oturumları ekler.
* **sysinfo** ile hedef oturumlar hakkında bilgi alınabilir.
* **network_status** ile listen ve established portlar listelenir.
* **hashdump** ile lm:ntlm hashleri alınabilir.
* **show_process** ile çalışan processlere ait bilgi alınabilir.
* **migrate -s <session\_id> -p <process\_id>** ile istenilen processe migrate olunabilir.
* **search -f \*.sql** bütün .sql uzantılı dosyaları listeler.
* **eventlog \-f \<event\_id> \-l \<category> \-c \<count>** ile istenilen event id kayıtları getirilebilir.







