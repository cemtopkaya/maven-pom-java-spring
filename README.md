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

# spring-boot konsol & web uygulamaları
spring  init  --build=maven  --dependencies=     --name=spring-console-app    --package-name=com.example.spring.console  spring-console-app
spring  init  --build=maven  --dependencies=web  --name=spring-web-app        --package-name=com.example.spring.web      spring-web-app

# düz konsol uygulaması
mvn archetype:generate \
  -DgroupId=com.example.maven.console \
  -DartifactId=maven-console-app \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

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
        <module>spring-console-app</module>
        <module>spring-web-app</module>
        <module>maven-console-app</module>
    </modules>

    <properties>
        <java.version>17</java.version>
        <spring-boot.version>3.5.4</spring-boot.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
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
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.11.0</version>
                    <configuration>
                        <source>\${maven.compiler.source}</source>
                        <target>\${maven.compiler.target}</target>
                    </configuration>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>

</project>
EOF
```

Her modül için ayrı ayrı `mvn spring-boot:run` gibi komutları çalıştırabilmek için `-pl <modül artifactId>` bayrağıyla `mvn spring-boot:run -pl spring-console-app`şeklinde koştururuz. Ama kök dizinde `mvn clean install` komutu gibi hem `spring-console-app` hem `web-app` modülleri için çalıştırılabilsin diye çocuk modülleri ana modüle `<modules>...</modules>` etiketinin arasında yazmamız gerekiyor. Modüllerin `pom.xml` dosyasına da `<parent>...</parent>` etiketine ana modülün bilgilerini yazarak iki yönlü olacak şekilde ilişkiyi kurarız:

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

sed -i '/<parent>/,/<\/parent>/d' maven-console-app/pom.xml
sed -i '/<modelVersion>4.0.0<\/modelVersion>/a\
  <parent>\
      <groupId>com.example</groupId>\
      <artifactId>multi-module-parent</artifactId>\
      <version>1.0.0</version>\
      <relativePath>../pom.xml</relativePath>\
  </parent>' maven-console-app/pom.xml

sed -i '/<parent>/,/<\/parent>/d' spring-console-app/pom.xml
sed -i '/<modelVersion>4.0.0<\/modelVersion>/a\
    <parent>\
        <groupId>com.example</groupId>\
        <artifactId>multi-module-parent</artifactId>\
        <version>1.0.0</version>\
        <relativePath>../pom.xml</relativePath>\
    </parent>' spring-console-app/pom.xml


sed -i '/<parent>/,/<\/parent>/d' spring-web-app/pom.xml
sed -i '/<modelVersion>4.0.0<\/modelVersion>/a\
    <parent>\
        <groupId>com.example</groupId>\
        <artifactId>multi-module-parent</artifactId>\
        <version>1.0.0</version>\
        <relativePath>../pom.xml</relativePath>\
    </parent>' spring-web-app/pom.xml
```

`spring-console-app` Uygulamasını paket üretmeden `spring-boot-maven-plugin` eklentisiyle koşturalım:
```sh
mvn -pl spring-console-app  clean package spring-boot:run
mvn -pl spring-web-app      clean package spring-boot:run
```


Aynı şeyi `maven-console-app` uygulaması için paket üretmeden koşturamayız. Bu yüzden maven ile derleyip, `exec-maven-plugin` eklentisiyle üretilen `jar` dosyasını koşturalım:
```sh
mvn -pl maven-console-app   clean package exec:java -Dexec.mainClass=com.example.maven.console.App
```

### mvn Komutu

Şimdi mvn komutuyla eklentileri nasıl çalıştırdığımızı inceleyelim. 

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
mvn help:describe -Dplugin=exec

# pom.xml içinde eklentiler tanımlıysa kısa adlarıyla da maven reposunda bulur ve yardımı görüntüleriz:
mvn help:describe -Dplugin=spring-boot
# Ancak pom.xml'de ilgili eklenti yoksa group adıyla eklentinin yardım belgelerine erişebiliriz:
mvn help:describe -Dplugin=org.springframework.boot:spring-boot-maven-plugin

# Özellikle bir sürüm numarasına ait sorgulama yapabiliriz:
mvn help:describe -Dplugin=org.springframework.boot:spring-boot-maven-plugin:3.5.4
# yahut sürüm numarası bayrak olarak verilebilir:
mvn help:describe -Dplugin=org.springframework.boot:spring-boot-maven-plugin -DpluginVersion=3.5.4

# Her eklenti için geçerli olmasa da, eklentinin goal'ü olarak help'i koşturmak da mümkün:
mvn exec:help
mvn exec:help -Ddetail=true 
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
mvn clean -pl spring-console-app

# Java 17 kullanarak spring-console-app modülünden paket üretir
mvn package -pl spring-console-app -Dmaven.compiler.source=17 -Dmaven.compiler.target=17

# hem clean hem package aşamalarını tüm modüller için koşar
mvn clean package -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
# hem clean hem package aşamalarını spring-console-app için koşar
mvn clean package -pl spring-console-app -Dmaven.compiler.source=17 -Dmaven.compiler.target=17
```

Bu aşamalarda kullanılacak bayrakları (`-Dmaven.compiler.source=17` ve `-Dmaven.compiler.target=17`) mvn komutu `pom.xml` dosyasında `<properties>...</properties>` etiketi içinde arar ve bulursa kullanır. Eğer bayrak olarak konsol komutuna verilmişse `properties` içindeki değerleri ezerek konsoldaki değerleri kullanılır.

`pom.xml`:
```xml
...
    <properties>
        ...
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        ...
    </properties>
...
```

#### exec-maven-plugin

Maven dünyasında `exec-maven-plugin` dediğimiz eklenti, komut satırı işlerimizi yapmamızı sağlıyor. Aşağıdaki komutta eklentiyi tam sürümüyle, yani `3.1.0` ile ve `java` goal'ünü çağırıyoruz, sonra `-Dexec.mainClass` parametresiyle hangi sınıfın `main` metodunu tetikleyeceğimizi belirtiyoruz, mvn komutuna `-pl maven-console-app` ile sadece o modül üzerinde işlem yap diyoruz ki bütün proje modüllerinde koşmasın komutumuzu. 

```sh
mvn -pl maven-console-app   package
mvn -pl maven-console-app   org.codehaus.mojo:exec-maven-plugin:3.1.0:java -Dexec.mainClass=com.example.maven.console.App
```

Şimdi işin numarası şu: Bu parametreleri ve plugin ayarlarını `pom.xml` dosyanıza yazarsanız, mesela plugin’in versiyonunu, çalıştırılacak sınıfı, hedef modülü, vs. orada tanımlarsanız, konsolda bu kadar uzun uzadıya komut yazmaya gerek kalmaz. Aşağıdaki `pom.xml` ile artık komutumuz `mvn exec:java -pl maven-console-app` olur. Zaten `mainClass` tanımı `pom.xml` içinde olduğu için tekrar yazmana gerek kalmaz, hem kısalır hem de temiz görünür.

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>exec-maven-plugin</artifactId>
      <version>3.1.0</version>
      <configuration>
        <mainClass>com.example.maven.console.App</mainClass>
      </configuration>
    </plugin>
  </plugins>
</build>
```

Bir örnek daha yapalım mı?

**Örnek: Komut satırında yazı yazıp, dizin yaratmak**

```sh
mvn org.codehaus.mojo:exec-maven-plugin:3.1.0:exec -Dexec.executable=mkdir -Dexec.args="new_folder"

# iki komut yan yana:
mvn org.codehaus.mojo:exec-maven-plugin:3.1.0:exec -Dexec.executable=bash -Dexec.args="-c 'echo Hello && mkdir new_folder'"

# pom.xml'de eklentiye dair bilgiler varsa olan bilgileri kullanarak yoksa bu eklentiyi merkezi Maven deposundan çekip kullanır:
mvn exec:exec -Dexec.executable=mkdir -Dexec.args="-p new_folder"
```

Burada `:exec` golünü çağrılıyor, `mkdir` komutu çalıştırılıyor ve `new_folder` isimli klasör oluşturuluyor.

Şimdi bu komutlar spring-console-app uygulamasında koşacağı için `spring-console-app/pom.xml`'i güncelleyelim:

```sh
mvn   -pl spring-console-app    exec:java@run-java-app          
mvn   -pl spring-console-app    exec:exec@make-directory         
mvn   -pl spring-console-app    exec:exec@complex-shell-command  
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

Aşağıdaki gibi `spring-boot-maven-plugin` eklentisinin altına `exec-maven-plugin` eklentisini `<build><plugins><plugin>....` etiketlerine yazalım:

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

> `<build>....</build>` Etiketi, projenin nasıl derleneceğini, test edileceğini, paketleneceğini ve çalıştırılacağını belirten bölümdür.
>
> Pluginler ise bu “build sürecinde yapılacak özel işler” için kullanılan araçlar gibidir. Mesela derleme, test çalıştırma, paketleme, veya bizim örnekte olduğu gibi Java programı başlatma veya kabuk komutları çalıştırma… Bunların tamamı “build aşamasında çalışan adımlar”dır. Dolayısıyla pluginler doğrudan `<build><plugins><plugin>....`, şeklinde `build->plugins->plugin` etiketi altında tanımlanır ki Maven onları build sürecine entegre edebilsin.

### Derle ve Çalıştır

Buraya kadar `exec-maven-plugin` eklentisinin `exec:java` ile ve `spring-boot` eklentisinin `:run` golüyle uygulamayı derleyip çalıştırdığı gördük (`mvn spring-boot:run`). Şimdi derleme ve çalıştır kısımlarını ayrı ayrı işletelim.

Modülleri ayrı ayrı aşağıdaki komutlarla derleyip, paketleyebiliriz. 
Aşağıdaki komutla `thin jar` oluşturulup tüm bağımlılıklar `target/lib` dizinine yazılır. Uygulamayı başlatmak için classpath (`java -cp`) ile bağımlılıkları vermek gerekir. 

> **Fat jar** (ya da uber jar), uygulamanızın kodları ve tüm bağımlılıklarının bir arada tek bir jar dosyasında bulunduğu Java arşividir. Bu sayede uygulama, tüm kütüphanelerle birlikte tek dosya olarak çalıştırılabilir (java -jar ile) ve başka kütüphanelere ihtiyaç duymaz. Ancak fat jar dosyaları genellikle büyük olur çünkü içinde tüm bağımlılıklar vardır. Bu da aynı kütüphanelerin farklı projelerde tekrar paketlenmesine ve sürüm uyuşmazlıklarına yol açabilir.
>
> **Thin jar** ise sadece sadece uygulama kodunuzu ve onu çalıştırmak için gereken temel bilgileri içerir, bağımlılıkları içermez. Bağımlılıklar çalışma zamanında dışarıdan sağlanır veya yüklenir. Bu yüzden thin jar dosyası küçüktür ve bağımlılıklar bağımsız yönetilebilir. Thin jar'lar, container ortamlarında veya modüler yapılarda daha esnek kullanım sağlar.
>
> Maven ile fat jar genellikle `maven-shade-plugin` veya Spring Boot’un kendi paketleme özellikleriyle oluşturulur. Thin jar için ise Spring Boot Thin Launcher gibi araçlar kullanılır.
>
> Spring Boot’un *fat jar* yapısı, `java -jar` ile çalıştırılması için tasarlanmıştır. *Fat jar* kullanıyorsanız, çalıştırmak için mutlaka `java -jar` komutunu kullanın. Bu, Spring Boot’un özel *class loader* mekanizmasını devreye sokar.

`spring-boot:repackage` ile *fat jar* oluşturalım ve `jar` dosyasından çalıştıralım. Ancak `:repackage` golünden önce derleme (`compile`), test (`test`) aşamalarını da geçecek paketleme (`package`) aşamasını koşmamız gerekiyor. Böylece paketlenecek `jar` çıktısı oluşsun: 

```sh
mvn  -pl spring-console-app    clean   package   spring-boot:repackage
java -jar spring-console-app/target/spring-console-app-0.0.1-SNAPSHOT.jar
```

Şimdi *thin jar* olacak şekilde `maven-console-app` modülünü derleyelim:
```sh
mvn clean 
mvn compile
mvn jar:jar \
      -Djar.archive.manifest.addClasspath=true        \
      -Djar.archive.manifest.classpathPrefix=lib/     \
      -Djar.archive.manifest.mainClass=com.example.maven.console.App \
      -pl maven-console-app
mvn dependency:copy-dependencies -DoutputDirectory=target/lib
```

Tek komutta:
```sh
mvn clean \
    compile \
    dependency:copy-dependencies \
      -DoutputDirectory=target/lib \
    org.apache.maven.plugins:maven-jar-plugin:3.3.0:jar \
      -Djar.archive.manifest.mainClass=com.example.maven.console.App \
      -Djar.archive.manifest.addClasspath=true \
      -Djar.archive.manifest.classpathPrefix=lib/ \
    -pl maven-console-app
```

Tüm parametreleri pom.xml içinde belirterek komut satırını kısaltabiliriz:

`maven-console-app/pom.xml`:
```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>3.3.0</version>
        <configuration>
          <archive>
            <manifest>
              <mainClass>com.example.maven.console.App</mainClass>
              <addClasspath>true</addClasspath>
              <classpathPrefix>lib/</classpathPrefix>
            </manifest>
          </archive>
        </configuration>
      </plugin>
    </plugins>
  </build>
```


```sh
cat > maven-console-app/pom.xml << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>com.example</groupId>
    <artifactId>multi-module-parent</artifactId>
    <version>1.0.0</version>
    <relativePath>../pom.xml</relativePath>
  </parent>
  <groupId>com.example.maven.console</groupId>
  <artifactId>maven-console-app</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>maven-console-app</name>
  <url>http://maven.apache.org</url>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>3.3.0</version>
        <configuration>
          <archive>
            <manifest>
              <mainClass>com.example.maven.console.App</mainClass>
              <addClasspath>true</addClasspath>
              <classpathPrefix>lib/</classpathPrefix>
            </manifest>
          </archive>
        </configuration>
      </plugin>
    </plugins>
  </build>

</project>
EOF
```
Komutun son hali:

```sh
mvn clean \
    compile \
    dependency:copy-dependencies \
      -DoutputDirectory=target/lib \
    jar:jar \
    -pl maven-console-app
```

`dependency:copy-dependencies -DoutputDirectory=target/lib` için `maven-console-app/pom.xml` dosyasını tekrar yazalım:
```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-dependency-plugin</artifactId>
      <version>3.8.1</version> <!-- Güncel sürümü kontrol edin -->
      <executions>
        <execution>
          <id>copy-dependencies</id>
          <phase>package</phase> <!-- package aşamasında çalışacak -->
          <goals>
            <goal>copy-dependencies</goal>
          </goals>
          <configuration>
            <outputDirectory>${project.build.directory}/lib</outputDirectory> <!-- Bağımlılıklar buraya kopyalanacak -->
            <includeScope>runtime</includeScope> <!-- runtime scope'daki bağımlılıkları kopyalar -->
            <!-- İsterseniz filtreleme yapabilirsiniz, örn.:
            <excludeGroupIds>org.unwanted</excludeGroupIds> 
            -->
          </configuration>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```


```sh
cat > /workspace/multi-module/maven-console-app/pom.xml << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>com.example</groupId>
    <artifactId>multi-module-parent</artifactId>
    <version>1.0.0</version>
    <relativePath>../pom.xml</relativePath>
  </parent>
  <groupId>com.example.maven.console</groupId>
  <artifactId>maven-console-app</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>maven-console-app</name>
  <url>http://maven.apache.org</url>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.8.1</version> <!-- Güncel sürümü kontrol edin -->
        <executions>
          <execution>
            <id>copy-dependencies</id>
            <phase>package</phase> <!-- package aşamasında çalışacak -->
            <goals>
              <goal>copy-dependencies</goal>
            </goals>
            <configuration>
              <outputDirectory>\${project.build.directory}/lib</outputDirectory> <!-- Bağımlılıklar buraya kopyalanacak -->
              <includeScope>runtime</includeScope> <!-- runtime scope'daki bağımlılıkları kopyalar -->
              <!-- İsterseniz filtreleme yapabilirsiniz, örn.:
              <excludeGroupIds>org.unwanted</excludeGroupIds> 
              -->
            </configuration>
          </execution>
        </executions>
      </plugin>
      
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>3.3.0</version>
        <configuration>
          <archive>
            <manifest>
              <mainClass>com.example.maven.console.App</mainClass>
              <addClasspath>true</addClasspath>
              <classpathPrefix>lib/</classpathPrefix>
            </manifest>
          </archive>
        </configuration>
      </plugin>
    </plugins>
  </build>

</project>
EOF
```

Bağımlılıkları `target/lib` içinde olan `jar` dosyamızı koşturalım:
```sh
java -cp "maven-console-app/target/classes:maven-console-app/target/dependency/*" com.example.maven.console.App

jar -xf maven-console-app/target/maven-console-app-1.0-SNAPSHOT.jar META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
# veya jar dosyasının yolunu göstererek koşturabiliriz ancak manifest dosyasında main metodunun yeri olmak zorunda.
#
# maven-console-app/target/maven-console-app-1.0-SNAPSHOT.jar Dosyasından META-INF/MANIFEST.MF içeriği:
#
# Manifest-Version: 1.0
# Created-By: Maven JAR Plugin 3.3.0
# Build-Jdk-Spec: 17
# Main-Class: com.example.maven.console.App

# Artık MANIFEST.MF içinde Main-Class olduğu için doğrudan jar dosyasını çalıştırabiliriz:
java -jar maven-console-app/target/maven-console-app-1.0-SNAPSHOT.jar
```

`maven-console-app` Modülünü `fat jar` haline getirebiliriz. Bunun için en çok kullanılan yöntemlerden biri `maven-assembly-plugin` veya `maven-shade-plugin` kullanmaktır. Oluşan jar dosyasında tüm bağımlılıklar artifaktın içine ekleneceğinden classpath (`java -cp`) ile bağımlılıkları vermeye gerek kalmaz.

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-assembly-plugin</artifactId>
  <version>3.1.1</version>
  <configuration>
    <descriptorRefs>
      <descriptorRef>jar-with-dependencies</descriptorRef>
    </descriptorRefs>
    <archive>
      <manifest>
        <mainClass>com.example.maven.console.App</mainClass> <!-- Ana sınıfınızın tam yolu -->
      </manifest>
    </archive>
  </configuration>
  <executions>
    <execution>
      <id>make-assembly</id>
      <phase>package</phase>
      <goals>
        <goal>single</goal>
      </goals>
    </execution>
  </executions>
</plugin>
```

```sh
cat > maven-console-app/pom.xml << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>com.example</groupId>
    <artifactId>multi-module-parent</artifactId>
    <version>1.0.0</version>
    <relativePath>../pom.xml</relativePath>
  </parent>
  <groupId>com.example.maven.console</groupId>
  <artifactId>maven-console-app</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>maven-console-app</name>
  <url>http://maven.apache.org</url>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.8.1</version> <!-- Güncel sürümü kontrol edin -->
        <executions>
          <execution>
            <id>copy-dependencies</id>
            <phase>package</phase> <!-- package aşamasında çalışacak -->
            <goals>
              <goal>copy-dependencies</goal>
            </goals>
            <configuration>
              <outputDirectory>${project.build.directory}/lib</outputDirectory> <!-- Bağımlılıklar buraya kopyalanacak -->
              <includeScope>runtime</includeScope> <!-- runtime scope'daki bağımlılıkları kopyalar -->
              <!-- İsterseniz filtreleme yapabilirsiniz, örn.:
              <excludeGroupIds>org.unwanted</excludeGroupIds> 
              -->
            </configuration>
          </execution>
        </executions>
      </plugin>
      
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>3.3.0</version>
        <configuration>
          <archive>
            <manifest>
              <mainClass>com.example.maven.console.App</mainClass>
              <addClasspath>true</addClasspath>
              <classpathPrefix>lib/</classpathPrefix>
            </manifest>
          </archive>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-assembly-plugin</artifactId>
        <version>3.1.1</version>
        <configuration>
          <descriptorRefs>
            <descriptorRef>jar-with-dependencies</descriptorRef>
          </descriptorRefs>
          <archive>
            <manifest>
              <mainClass>com.example.maven.console.App</mainClass> <!-- Ana sınıfınızın tam yolu -->
            </manifest>
          </archive>
        </configuration>
        <executions>
          <execution>
            <id>make-assembly</id>
            <phase>package</phase>
            <goals>
              <goal>single</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

    </plugins>
  </build>

</project>
EOF
```

```sh
cd /workspace/multi-module
mvn  -pl  maven-console-app       clean   package 
java -jar maven-console-app/target/maven-console-app-1.0-SNAPSHOT-jar-with-dependencies.jar
```

### Birim Testler ve Kapsama Raporu

#### Temel Test Komutları

- Tüm testleri çalıştır
  ```sh
  mvn test
  ```
  Bu komut:
  - Tüm test sınıflarını bulur (`*Test.java`, `Test*.java`, `*TestCase.java` pattern'lerini)
  - *JUnit*, *TestNG* gibi test framework'lerini otomatik algılar
  - `maven-surefire-plugin` ya da `failsafe-plugin` üzerinden testleri çalıştırır.
  - Test sonuçlarını konsola yazdırır
  - `target/surefire-reports/` klasöründe detaylı raporlar oluşturur

- Maven `test-compile` ile tüm test sınıflarını derleyip edip `*.class` dosyalarını oluştur
  ```sh
  mvn clean test-compile
  ```

- Testleri temizleyip çalıştırır
  ```sh
  mvn clean test
  ```

- Tüm test sınıflarını listele
  ```sh
  find . -name "*Test.java" | xargs -I {} basename {} .java | sort
  ```

- Belirli bir test sınıfını çalıştır
  ```sh
  mvn test -Dtest=TestClassName
  ```

- Belirli bir test metodunu çalıştır
  ```sh
  mvn test -Dtest=TestClassName#testMethodName
  ```

- Wildcard ile test sınıflarını çalıştır
  ```sh
  mvn test -Dtest="*ServiceTest,User*Test,Order*Test"
  ```

- Birden fazla test sınıfını çalıştır
  ```sh
  mvn test -Dtest="UserServiceTest,OrderServiceTest"
  ```

#### Multi-Module Projede Test Komutları

- Belirli bir modülde testleri çalıştır
  ```sh
  mvn test -pl spring-console-app
  ```

- Belirli modül ve bağımlılıklarında testleri çalıştır
  ```sh
  mvn test -pl spring-console-app -am
  ```

- Birden fazla modülde testleri çalıştır
  ```sh
  mvn test -pl spring-console-app,maven-console-app
  ```

- Test başarısızlıklarında durma
  ```sh
  mvn test -Dmaven.test.failure.ignore=true
  ```

- Paralel test çalıştırma
  ```sh
  mvn test -Dparallel=methods -DthreadCount=4
  ```

#### Test Raporları ve Detaylar

Java ekosisteminde üretilebilecek başlıca rapor türleri:
1. Test Execution Raporları

    * Surefire Reports (Maven)
    * Test Results (Gradle)
    * JUnit HTML raporları
    * TestNG raporları

2. Code Coverage Raporları

    * JaCoCo raporları
    * Cobertura raporları
    * Emma raporları

3. Kod Kalite Raporları

    * SonarQube raporları
    * SpotBugs raporları
    * PMD raporları
    * Checkstyle raporları

4. Performans Test Raporları

    * JMeter raporları
    * Gatling raporları

Rapor üreteç olarak **Surefire** ve kapsama raporu için **Jacoco**'yu inceleyelim.

##### surefire-report-plugin

```sh
mvn help:describe -Dplugin=org.apache.maven.plugins:maven-surefire-report-plugin:3.5.3
mvn help:describe -Dplugin=org.apache.maven.plugins:maven-surefire-report-plugin:3.5.3 -Ddetail=true
```

**surefire-report:report** ile birim testlerin başarılı veya başarısız tamamlandığına dair sonuçları raporlarda gösterilir.



- Detaylı test çıktısı ile

  ```sh
  mvn  -pl maven-console-app   test   -Dsurefire.printSummary=true
  ```
  Etkileri:
    * Sınıflar ve test sınıfları derlenir `*.class` dosyaları oluşturulur
    * Testler koşar ve rapor dosyaları `*.txt` ve `*.xml` olacak şekilde üretilir
  ```sh
  [root@b8012209bf0b maven-console-app]# tree target/classes target/test-classes target/surefire-reports
  target/classes
  └── com
      └── example
          └── maven
              └── console
                  └── App.class
  target/test-classes
  └── com
      └── example
          └── maven
              └── console
                  └── AppTest.class
  target/surefire-reports
  ├── TEST-com.example.maven.console.AppTest.xml
  └── com.example.maven.console.AppTest.txt

  8 directories, 4 files
  [root@b8012209bf0b maven-console-app]# cat target/surefire-reports/com.example.maven.console.AppTest.txt
  -------------------------------------------------------------------------------
  Test set: com.example.maven.console.AppTest
  -------------------------------------------------------------------------------
  Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.031 sec
  ```

- Sure Fire ile rapor oluşturma
  ```sh
  mvn    -pl maven-console-app    surefire-report:report
  ```

  HTML formatında testlerin raporu target/reports dizininde üretilecek:
  ```sh
  [root@b8012209bf0b target]# tree -L 1 reports/ --dirsfirst
  reports/
  ├── css
  ├── fonts
  ├── images
  ├── img
  ├── js
  └── surefire.html
  ```


##### jacoco-maven-plugin

```sh
mvn help:describe -Dplugin=org.jacoco:jacoco-maven-plugin
mvn help:describe -Dplugin=org.jacoco:jacoco-maven-plugin -Ddetail=true
```
**jacoco:prepare-agent**, testlerin çalışırken kapsama verisini toplayabilmesi için JVM’e bir *JaCoCo* ajanı ekleme işini yapar.
Testler başlar ve JVM içindeki JaCoCo ajanı, hangi sınıfın hangi satırının çalıştığını “not alır”. Bu bilgileri `target/jacoco.exec` adında ikili (binary) bir dosyaya kaydeder. 

**jacoco:report** ile birim testlerin Java kodlarının kapsama raporu (HTML, XML, CSV biçimlerinde) gösterilir.
Rapor almak için ayrıca `jacoco:report` (tek modül) veya `jacoco:report-aggregate` (çok modüllü) hedefini çalıştırmak gerekir.

```sh
mvn -pl maven-console-app \
  clean \
  org.jacoco:jacoco-maven-plugin:0.8.13:prepare-agent \
  test \
  org.jacoco:jacoco-maven-plugin:0.8.13:report
```

Yukarıdaki komutta yapılacak işlerin sırası şöyledir: `clean → prepare-agent → test → report`

**Bu zincir şunları yapar:**
1. **clean** → - önceki koşulardan üretilen `target` dizinlerini temizler,
1. **prepare-agent** → `argLine` içine `-javaagent` ekler, JaCoCo ölçüm cihazı olan `target/jacoco.exec`'i yaratıp izlemeye başlatır. `prepare-agent` çalışmadan test’i çalıştırırsan, JVM’e JaCoCo ajanı eklenmez. Bu durumda testler çalışır ama kapsama ölçülmez.
1. **test** → Testler çalışır, JaCoCo `target/jacoco.exec` dosyasına kapsama verilerini yazar.
1. **report** → `target/jacoco.exec`’ten HTML/XML raporlarını `target/site/jacoco/` içine üretir.


```shell
maven-console-app/target/
├── classes
│   └── ...
├── generated-sources
│   └── ...
├── generated-test-sources
│   └── ...
├── jacoco.exec                 <----- jacoco:prepare-agent   Tarafından oluşturulur
├── maven-status
│   └── ...
├── site                        <----- jacoco:report          Tarafından oluşturulur
│   └── jacoco
│       ├── com.example.maven.console
│       ├── index.html
│       ├── jacoco-resources
│       ├── jacoco-sessions.html
│       ├── jacoco.csv
│       └── jacoco.xml
├── surefire-reports
│   └── ...
└── test-classes
    └── ...
```

Bu komut çalıştığında konsoldaki çıktılarını özetleyerek inceleyelim:
```shell
[root@b8012209bf0b multi-module]# mvn -pl maven-console-app \
                                      clean \
                                      org.jacoco:jacoco-maven-plugin:0.8.13:prepare-agent \
                                      test \
                                      org.jacoco:jacoco-maven-plugin:0.8.13:report
...
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ maven-console-app ---
[INFO] Deleting /workspace/multi-module/maven-console-app/target
[INFO] 
[INFO] --- jacoco-maven-plugin:0.8.13:prepare-agent (default-cli) @ maven-console-app ---
[INFO] argLine set to -javaagent:/root/.m2/repository/org/jacoco/org.jacoco.agent/0.8.13/org.jacoco.agent-0.8.13-runtime.jar=destfile=/workspace/multi-module/maven-console-app/target/jacoco.exec
...
[INFO] --- maven-compiler-plugin:3.11.0:compile (default-compile) @ maven-console-app ---
[INFO] Changes detected - recompiling the module! :source
[INFO] Compiling 1 source file with javac [debug target 17] to target/classes
... 
[INFO] --- maven-compiler-plugin:3.11.0:testCompile (default-testCompile) @ maven-console-app ---
[INFO] Changes detected - recompiling the module! :dependency
[INFO] Compiling 1 source file with javac [debug target 17] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ maven-console-app ---
[INFO] Surefire report directory: /workspace/multi-module/maven-console-app/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running com.example.maven.console.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.02 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO] 
[INFO] --- jacoco-maven-plugin:0.8.13:report (default-cli) @ maven-console-app ---
[INFO] Loading execution data file /workspace/multi-module/maven-console-app/target/jacoco.exec
[INFO] Analyzed bundle 'maven-console-app' with 1 classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.497 s
[INFO] Finished at: 2025-08-10T21:07:53+03:00
[INFO] ------------------------------------------------------------------------
```

* `[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ maven-console-app ---`:
  - önceki koşulardan üretilen `target` dizini temizlenir, 
* `[INFO] --- jacoco-maven-plugin:0.8.13:prepare-agent (default-cli) @ maven-console-app ---`:
  - jacoco ajanı yaratılır,
* `[INFO] --- maven-compiler-plugin:3.11.0:compile (default-compile) @ maven-console-app ---`:
  - `*.java` kodları derlenir
* `[INFO] --- maven-compiler-plugin:3.11.0:testCompile (default-testCompile) @ maven-console-app ---`:
  - birim test sınıfları derlenir
* `[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ maven-console-app ---`:
  - birim testleri koşar
  - birim test sonuçlarının `.txt` ve `.xml` olarak raporları oluşturulur,
* `[INFO] --- jacoco-maven-plugin:0.8.13:report (default-cli) @ maven-console-app ---`:
  - ve `surefire` eklentisi üzerinden kod kapsama raporu üretilir.


Bu akışı `pom.xml` dosyasına yazmak için kullanacağımız maven hayat çevrimi aşamalarını bulalım.

* `test` öncesinde `jacoco-agent` yaratmak için `jacoco:prepare-agent` golünü `initialize` aşamasında çalıştırıyoruz.
* `test` sonrasında testlerin, kod kapsama raporunu oluşturmak için `jacoco:report` golünü `verify` aşamasında çalıştırıyoruz.
* artık `mvn clean verify` aşamalarını çalıştıracağız ki `test` seviyesinin ötesine geçip `verify` aşamasında rapor üretebilelim.  

Şimdi bu jacoco ile kapsam raporu üretmek için kullandığımız komutu, `maven-console-app/pom.xml` içine eklentiler üzerinden yazalım, daha sonra tüm modüllerde çalışmasını isteyeceğiz:

```xml
  <build>
    <plugins>

      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>0.8.13</version>
        <executions>
          <!-- 1. Testten önce ajanı hazırla -->
          <execution>
            <id>prepare-agent</id>
            <phase>initialize</phase>
            <goals>
              <goal>prepare-agent</goal>
            </goals>
          </execution>

          <!-- 2. Test bittikten sonra raporu üret -->
          <execution>
            <id>report</id>
            <phase>verify</phase>
            <goals>
              <goal>report</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

    </plugins>
  </build>
```


