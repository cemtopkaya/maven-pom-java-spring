# Spring Uygulamasını Anlamak

Konsol ve web uygulaması olarak 2 modülden oluşacak. Bu projede `pom.xml` dosyası, bağımlılıklar, eklentileri nasıl kullanabileceğimi deneyeceğim.

#### Spring Boot Cli

### Spring Boot Cli Kurulumu

```sh
wget https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-cli/3.5.4/spring-boot-cli-3.5.4-bin.tar.gz -O springcli.tar.gz
tar -xvzf springcli.tar.gz
mv spring-3.5.4 /opt/spring
echo 'export PATH=/opt/spring/bin:$PATH' >> /etc/profile.d/spring.sh
source /etc/profile.d/spring.sh
rm -rf /tmp/spring-cli
```

### Projeleri Başlat

Komutlar & Açıklamaları:

- `--dependencies=` boş bırakıldı çünkü konsol uygulamasında kütüphane yok ancak `web-app` için `web` kütüphanesi gelecek.
- `--name` proje ismi
- `--package-name` paket yolu

```sh
mkdir -p /workspace/multi-module && cd /workspace/multi-module
spring  init  --build=maven  --dependencies=     --name=console-app  --package-name=com.example.console  console-app
spring  init  --build=maven  --dependencies=web  --name=web-app      --package-name=com.example.web      web-app

cat >> pom.xml << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>multi-module-parent</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>

    <modules>
        <module>console-app</module>
        <module>web-app</module>
    </modules>

    <properties>
        <java.version>17</java.version>
        <spring-boot.version>3.5.4</spring-boot.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>\${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <version>\${spring-boot.version}</version>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>

</project>
EOF
```

Her modül için ayrı ayrı `mvn spring-boot:run` gibi komutları çalıştırabilmek için `-pl <modül artifactId>` bayrağıyla `mvn spring-boot:run -pl console-app`şeklinde koştururuz. Ama kök dizinde `mvn clean install` komutu gibi hem `console-app` hem `web-app` modülleri için çalıştırılabilsin diye çocuk modülleri ana modüle `<modules>...</modules>` etiketinin arasında yazmamız gerekiyor. Modüllerin `pom.xml` dosyasına da `<parent>...</parent>` etiketine ana modülün bilgilerini yazarak iki yönlü olacak şekilde ilişkiyi kurarız:

```xml
<parent>
    <groupId>com.example</groupId>
    <artifactId>multi-module-parent</artifactId>
    <version>1.0.0</version>
</parent>
```

`sed` komut satırı aracı `<modelVersion>4.0.0</modelVersion>` satırını buluyor ve hemen altına parent XML bloğunu ekliyor:

```sh
cd /workspace/multi-module

sed -i '/<modelVersion>4.0.0<\/modelVersion>/a\
    <parent>\
        <groupId>org.springframework.boot</groupId>\
        <artifactId>spring-boot-starter-parent</artifactId>\
        <version>3.5.4</version>\
    </parent>' pom.xml

sed -i '/<parent>/,/<\/parent>/d' console-app/pom.xml
sed -i '/<modelVersion>4.0.0<\/modelVersion>/a\
    <parent>\
        <groupId>com.example</groupId>\
        <artifactId>multi-module-parent</artifactId>\
        <version>1.0.0</version>\
        <relativePath>../pom.xml</relativePath>\
    </parent>' console-app/pom.xml


sed -i '/<parent>/,/<\/parent>/d' web-app/pom.xml
sed -i '/<modelVersion>4.0.0<\/modelVersion>/a\
    <parent>\
        <groupId>com.example</groupId>\
        <artifactId>multi-module-parent</artifactId>\
        <version>1.0.0</version>\
        <relativePath>../pom.xml</relativePath>\
    </parent>' web-app/pom.xml
```

`console-app` Uygulamasını paket üretmeden `spring-boot-maven-plugin` eklentisiyle koşturalım:
```sh
mvn clean package -pl console-app  spring-boot:run
mvn clean package -pl web-app      spring-boot:run
```

### mvn Komutu

```sh
mvn <plugin-prefix>:<goal>
mvn <plugin-group-id>:<plugin-artifact-id>[:<plugin-version>]:<goal>
``` 

```xml
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
	            <version>3.5.4</version>
			</plugin>
```

Eklentinin gollerini görmek için aşağıdaki komutlardan birini çalıştırabiliriz:
```sh
mvn help:describe -Dplugin=spring-boot
mvn help:describe -Dplugin=org.springframework.boot:spring-boot-maven-plugin
mvn help:describe -Dplugin=org.springframework.boot:spring-boot-maven-plugin -DpluginVersion=3.5.4
``` 

 
**MVN Lifecycle Phases:**

- validate
- initialize
- generate-sources
- process-sources
- generate-resources
- process-resources
- compile
- process-classes
- generate-test-sources
- process-test-sources
- generate-test-resources
- process-test-resources
- test-compile
- process-test-classes
- test
- prepare-package
- package
- pre-integration-test
- integration-test
- post-integration-test
- verify
- install
- deploy
- pre-clean
- clean
- post-clean
- pre-site
- site
- post-site
- site-deploy

Şimdi yukarıdaki hayat çevrimi aşamalarından `clean`'i inceleyelim:

```sh
mvn clean
```

`mvn clean` komutu çalıştığında devreye giren eklenti, Maven'in standart `maven-clean-plugin` eklentisidir. Bu eklenti, projenin derleme tarafından oluşturulmuş dosyalarını (genellikle target dizini içeriği gibi) temizlemek için kullanılır. `maven-clean-plugin` Eklentisi `pom.xml` dosyasında tanımlanmış olmasa dahi Maven'ın kendi içindeki `maven-model-builder` kütüphanesi içinde yer alan XML biçiminde bir POM dosyası olan **Super POM**'dan bu eklentiyi ve eklentinin `clean` goal'ünü çalıştırır.

> Maven'ın **Super POM**'u, tüm Maven projelerinin varsayılan temel yapılandırmasını içeren gizli bir POM dosyasıdır. Her Maven projesi sizin yazdığınız pom.xml dosyasının yanında otomatik olarak bu Super POM'dan da miras alır ve eğer siz kendi POM dosyanızda bazı ayarları belirtmezseniz, Super POM'daki varsayılanlar devreye girer.


```sh
# Tüm modülleri yahut bulunduğu dizinin modülünün target dizinini siler, üretilmiş artifaktlar silinir. 
mvn clean 
# -pl <modül artifactId> ile belirli bir modülün artifaktlarını siler  
mvn clean -pl console-app

# Java 17 kullanarak console-app modülünden paket üretir
mvn package -pl console-app -Dmaven.compiler.source=17 -Dmaven.compiler.target=17

# hem clean hem package aşamalarını tüm modüller için koşar
mvn clean package -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
# hem clean hem package aşamalarını console-app için koşar
mvn clean package -pl console-app -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
```

Bu anahtarları (`-Dmaven.compiler.source=17` ve `-Dmaven.compiler.target=17`) mvn komutu `pom.xml` dosyasında `<properties>...</properties>` etiketi içinde arar. Eğer bayrak olarak konsol komutuna verilmişse `properties` içindeki değerleri ezerek konsoldaki değerleri kullanılır.

`pom.xml`:
```xml
...
    <properties>
        <java.version>17</java.version>
        <spring-boot.version>3.5.4</spring-boot.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>
...
```

Maven dünyasında `exec-maven-plugin` dediğimiz eklenti, komut satırı işlerimizi yapmamızı sağlıyor. Burada “plugin”i tam sürümüyle, yani `3.1.0` ile çağırıyoruz, sonra `-Dexec.mainClass` parametresiyle hangi sınıfın `main` metodunu tetikleyeceğimizi belirtiyoruz, `-pl console-app` ile sadece o modül üzerinde işlem yap diyoruz ki gereksiz bütün projeyi sarmasın. 

```sh 
mvn org.codehaus.mojo:exec-maven-plugin:3.1.0:java -Dexec.mainClass=com.example.console.ConsoleAppApplication -pl console-app
```

Şimdi işin numarası şu: Bu parametreleri ve plugin ayarlarını `pom.xml` dosyanıza yazarsanız, mesela plugin’in versiyonunu, çalıştırılacak sınıfı, hedef modülü, vs. orada tanımlarsanız, konsolda bu kadar uzun uzadıya komut yazmaya gerek kalmaz. Aşağıdaki `pom.xml` ile artık komutumuz `mvn exec:java -pl console-app` olur. Zaten `mainClass` tanımı `pom.xml` içinde olduğu için tekrar yazmana gerek kalmaz, hem kısalır hem de temiz görünür.

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>exec-maven-plugin</artifactId>
      <version>3.1.0</version>
      <configuration>
        <mainClass>com.example.console.ConsoleAppApplication</mainClass>
      </configuration>
    </plugin>
  </plugins>
</build>
```

Bir örnek daha yapalım. 

**Örnek: Komut satırında yazı yazıp, dizin yaratmak**

```sh
mvn org.codehaus.mojo:exec-maven-plugin:3.1.0:exec -Dexec.executable=mkdir -Dexec.args="new_folder"

# iki komut yan yana:
mvn org.codehaus.mojo:exec-maven-plugin:3.1.0:exec -Dexec.executable=bash -Dexec.args="-c 'echo Hello && mkdir new_folder'"

# pom.xml'de eklentiye dair bilgiler varsa olan bilgileri kullanarak yoksa bu eklentiyi merkezi Maven deposundan çekip kullanır:
mvn exec:exec -Dexec.executable=mkdir -Dexec.args="-p new_folder"
```

Burada exec goal’ü çağrılıyor, `mkdir` komutu çalıştırılıyor ve `new_folder` isimli klasör oluşturuluyor.

Şimdi bu komutlar console-app uygulamasında koşacağı için `console-app/pom.xml`'i güncelleyelim:

```sh
mvn exec:java@run-java-app          -pl console-app 
mvn exec:exec@make-directory        -pl console-app 
mvn exec:exec@complex-shell-command -pl console-app 
```

`<build><plugins>` Etiketine `exec-maven-plugin` eklentisini ekleyelim:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

Aşağıdaki gibi `spring-boot-maven-plugin` eklentisinin altına `exec-maven-plugin` eklentisini yazalım:

```xml
<build>
  <plugins>
    <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
    </plugin>

    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>exec-maven-plugin</artifactId>
      <version>3.1.0</version>

      <!-- Java programını çalıştırmak için configuration -->
      <executions>
        <execution>
          <id>run-java-app</id>
          <goals>
            <goal>java</goal>
          </goals>
          <configuration>
            <mainClass>com.example.console.ConsoleAppApplication</mainClass>
          </configuration>
        </execution>

        <!-- Kabuk komutları çalıştırmak için execution -->
        <execution>
          <id>make-directory</id>
          <goals>
            <goal>exec</goal>
          </goals>
          <configuration>
            <executable>mkdir</executable>
            <arguments>
              <argument>new_folder</argument>
            </arguments>
          </configuration>
        </execution>

        <execution>
          <id>complex-shell-command</id>
          <goals>
            <goal>exec</goal>
          </goals>
          <configuration>
            <executable>bash</executable>
            <arguments>
              <argument>-c</argument>
              <argument>echo Hello; echo World</argument>
            </arguments>
          </configuration>
        </execution>

      </executions>
    </plugin>
  </plugins>
</build>
```

`<build>....</build>` Etiketi, projenin nasıl derleneceğini, test edileceğini, paketleneceğini ve çalıştırılacağını belirten bölümdür.

Pluginler ise bu “build sürecinde yapılacak özel işler” için kullanılan araçlar gibidir. Mesela derleme, test çalıştırma, paketleme, veya bizim örnekte olduğu gibi Java programı başlatma veya kabuk komutları çalıştırma… Bunların tamamı “build aşamasında çalışan adımlar”dır. Dolayısıyla pluginler doğrudan `<build><plugins><plugin>....`, şeklinde `build->plugins->plugin` etiketi altında tanımlanır ki Maven onları build sürecine entegre edebilsin.


### Derle ve Çalıştır

Modülleri ayrı ayrı aşağıdaki komutlarla derleyip, paketleyebiliriz. 
Aşağıdaki komutla `thin jar` oluşturulup tüm bağımlılıklar `target/lib` dizinine yazılır. Uygulamayı başlatmak için classpath (`java -cp`) ile bağımlılıkları vermek gerekir. 

```sh

java -cp "console-app/target/classes:console-app/target/dependency/*" com.example.console.ConsoleApp

# veya jar dosyasının yolunu göstererek:
java -jar console-app/target/console-app-1.0.0.jar
```
Eğer thin jar yani bağımlılıkları 
Aşağıdaki komutla `fat jar` oluşturulup tüm bağımlılıklar artifaktın içine ekleneceğinden classpath (`java -cp`) ile bağımlılıkları vermeye gerek kalmaz. Eğer thin jar yani bağımlılıkları 
```sh
cd /workspace/multi-module
mvn clean package dependency:copy-dependencies -pl console-app  -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
mvn clean package dependency:copy-dependencies -pl web-app      -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
```

veya ana `pom.xml` dizininde tüm alt modüller için bir kerede yapabiliriz:
```sh
cd /workspace/multi-module
mvn clean package -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
```

Yukarıdaki Ancak `mvn clean package -pl console-app`
mvn clean package dependency:copy-dependencies -Dmaven.compiler.source=17 -Dmaven.compiler.target=17

```sh
java -cp "console-app/target/classes:console-app/target/dependency/*" com.example.console.ConsoleApp
java -cp "web-app/target/classes:web-app/target/dependency/*" com.example.web.WebAppApplication
```


