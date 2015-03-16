# Allgemein
Diese einfache Implementierung einer Websuchmaschine entstand im Rahmen meiner
Maturitätsarbeit an der Kantonsschule Zürich Nord. Ich veröffentliche den Code
hier in der Hoffnung, dass vielleicht jemand etwas hieraus lernen kann, und dass
es dazu beiträgt praktisch zu zeigen, wie eine Websuchmaschine aufgebaut sein kann.

Es gibt vieles das man viel besser hätte lösen können; diese Suchmaschine liefert
zwar in der Regel recht schlechte Resultate, doch man muss bedenken, dass die
gesamte Implementierung (exklusiv einiger Libraries) mit lediglich 2000 Zeilen
Code auskommt.

# Abhängigkeiten
Um die Suchmaschine betreiben können muss auf deinem Computer eine aktuelle Version
von Ruby installiert sein. Danach musst du die Bibliothek "leveldb" in deinem
Betriebssystem installieren (ggf. Packagemanger verwenden).
Die nun weiter benötigten Bibliotheken für das Projekt können mittels Rubygems bequem
installiert werden, hierzu sollte man zuerst das Gem "Bundler" installieren, was
ermöglicht mit dem Befehl "bundle install" alle weiter benötigten Bibliotheken zu
installieren.

# Verwendung
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

# Copyright
© 2014-2015 Leonardo Schwarz (http://leoschwarz.com)
Der Quellcode darf gemäss der Bestimmungen in der Datei LICENSE verwendet werden.
Für die verwendeten Bibliotheken sind die jeweiligen Lizenzbedingungen zu berücksichtigen.
