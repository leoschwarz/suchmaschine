require 'pg'
require 'date'

$db = PG.connect(dbname: "suchmaschine", host: "10.0.1.12", user: "leo", password: "1234")

class Domain
  attr_reader :name, :last_scheduled
  
  def initialize(name, last_scheduled)
    @name = name
    @last_scheduled = DateTime.parse(last_scheduled)
  end
  
  def mark_time!
    @last_scheduled = DateTime.now
    $db.exec_params("UPDATE domains SET last_scheduled = $1 WHERE domain = $2", [@last_scheduled, @name])
  end
  
  def allowed?
    @last_scheduled < DateTime.now - Rational(1, 60*60*24)
  end  
  
#  def schedule
#    if @last_scheduled.nil?
#      new_time = DateTime.now + Rational(1, 60*60*24)
#    else
#      new_time = DateTime.parse(@last_scheduled) + Rational(1, 60*60*24)
#    end
#    
#    @last_scheduled = new_time
#    $db.exec_params("UPDATE domains SET last_scheduled = $1 WHERE domain = $2", [@last_scheduled, @name])
#    @last_scheduled
#  end
  
  # Gets an existing domain object for a given URL, or creates a new one if needed
  def self.for(url)
    m1 = /http:\/\/([a-zA-Z0-9\.-]+)/.match(url)
    m2 = /https:\/\/([a-zA-Z0-9\.-]+)/.match(url)
    if not m1.nil?
      domain_name = m1[1].downcase
    elsif not m2.nil?
      domain_name = m2[1].downcase
    else
      return nil
    end
    
    result = $db.exec_params("SELECT domain, last_scheduled FROM domains WHERE domain = $1", [domain_name])
    if result.ntuples == 1
      return Domain.new(result.getvalue(0,0), result.getvalue(0,1))
    elsif result.ntuples == 0
      $db.exec_params("INSERT INTO domains (domain) VALUES ($1)", [domain_name])
      return Domain.new(domain_name, nil)
    else
      raise "ERROR: Domain #{domain_name} registered #{result.ntuples} times!"
    end
  end
end

class Task
  attr_reader :url, :state, :done_at
  
  def initialize(url, state, done_at)
    @url = url
    @state = state
    @done_at = done_at
  end
  
  def allowed?
    domain = Domain.for(@url)
    domain.allowed?
  end
  
  def mark_done
    domain = Domain.for(@url)
    domain.mark_time!
    $db.exec_params("UPDATE tasklist SET state = 1, done_at = $2 WHERE url = $1", [@url, DateTime.now])
  end
  
  def store_result(html)
    require 'digest/md5'
    filename = "html/#{Digest::MD5.hexdigest(@url)}"
    f = open(filename, "w")
    f.write(html)
    f.close
    
    mark_done
  end
  
  def self.registered?(url)
    return $db.exec_params("SELECT url FROM tasklist WHERE url = $1", [url]).ntuples > 0
  end
  
  def self.sample(n=100)
    # FIXME: Zufallsauswahl
    # Idee:  Man könnte eine Spalte random einführen. Dort wird jeweils beim Schreiben in die Tabelle ein Zufallswert hineingesetzt.
    #        Diesen Zufallswert kombiniert man nun noch mit einer Stundenzahl oder so. Jetzt werden alle Einträge für die kleinste
    #        Stunde abgearbeitet, währned zu einem höheren Wert neue Einträge hinzugefügt werden. Hierdurch kann man vermeiden, dass 
    #        neue Einträge mit einem kleineren Zufallswert (beispielsweise) immer gecrawlt werden, während andere endlos darauf warten.
    
    results = $db.exec_params("SELECT (url) FROM tasklist WHERE state = 0 LIMIT $1", [n])
    results.map do |result|
      Task.new(result["url"], nil, nil)
    end
  end
  
#  def self.fetch
#    result = $db.exec("SELECT url, state, scheduled FROM tasklist WHERE scheduled <= CURRENT_TIMESTAMP AND state = 0 LIMIT 1")
#    #result = $db.exec_params("SELECT url, state, scheduled FROM tasklist WHERE scheduled <= $1 AND state = 0 LIMIT 1", [DateTime.now])
#    if result.ntuples == 0
#      return nil
#    end
#    
#    Task.new(result.getvalue(0,0), result.getvalue(0,1), result.getvalue(0,2))
#  end
  
  def self.insert(url)
    # check if already stored
    if self.registered? url
      return nil
    end
    
    # if not, insert into table
    $db.exec_params("INSERT INTO tasklist (url, state) VALUES ($1, $2)", [url, 0])
  end
end


