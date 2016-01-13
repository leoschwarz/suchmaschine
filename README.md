# About
BreakSearch originates in a school project of mine.
It's basically a full fledged search engine including a crawler, indexer and search frontend
and database backend written in Ruby. Its purpose is kind of a proof of concept how a search
engine works written in well documented Ruby code.

# Status
I'm currently working on porting it to Rubinius and make some more improvements on the project.
Goals for the future definitely include the possibility to update the index while search
requests are being handled and making the system self balanced. The clients should just be able
to connect to the network and execute the kind of task that is most needed right now.
Only the database backend is supposed to stay specialized (for now in the far future I could
see how something distributed might be fun to implement there too).

# Dependencies
You need to have an up to date ruby version installed. Currently also leveldb needs to be installed
because it's required by one library required by this project. You can use Ruby Bundler to install
the dependencies with `bundle install`.

# Running
Old instructions (in German), will be updated once there is more progress with the rewrite:
```
Falls du diese Software zum laufen bringen möchtest musst du einiges beachten.
Der Ablauf wird hier nur grob beschrieben, ansonsten kannst du bei Fragen aber
auch mich fragen, oder einfach den Quellcode inspizieren.

Zunächst einmal musst du im Verzeichnis config die Dateien durchgehen.
In config.yml kannst du verschiedene Umgebungen konfigurieren, die Parameter sollten
in den Kommentaren ausreichend erklärt sein.
In starting_points.yml kannst du die Startpunkte für den Crawler festlegen.

Nachdem du die Konfigurationen vorgenommen hast, musst du in deiner [Shell](https://de.wikipedia.org/wiki/Unix-Shell)
die Umgebungsvariabel `SEARCHENGINE_ENV` auf den Wert der gewünschten Umgebung setzen.
Wenn du das nicht machst wird dir beim nächsten Schritt eine Fehlermeldung angezeigt werden. :)

Nun startest du die Datenbank mit `ruby bin/database.rb`, sobald sie läuft kannst
du das Programm `util/url-seed.rb` starten um einige Starturls in die Datenbank zu laden.
Sobald dies fertig ist, kannst du einen Crawlerprozess starten indem du `bin/crawler.rb`
ausführst.

Leider ist es zur Zeit nicht möglich, dass die gecrawlten Seiten automatisch indexiert werden,
stattdessen ist es notwendig alle Crawler und die Datenbank zu beenden und dann das
Programm `bin/indexer.rb` aufzurufen. Sobald dieses fertig ist mit der Indexierung,
kann man das Frontend starten und mithilfe eines Webbrowsers Suchanfragen durchführen.

Die Verwendung ist vergleichsweise aufwändig, dieses System wurde aber auch nicht
primär dazu konstruiert einfach verwendbar zu sein.
```

# Copyright
© 2014-2016 Leonardo Schwarz (https://leoschwarz.com)
The source code is licensed under the GNU Affero General Public License.
You can find a copy of the license in the file LICENSE.

The required libraries all have their own licenses that you should check out individually.
