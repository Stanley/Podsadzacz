module CouchRestRails
  class Document < CouchRest::ExtendedDocument

    def self.use_database(db)
      db = [COUCHDB_CONFIG[:db_prefix], db.to_s, COUCHDB_CONFIG[:db_suffix]].join
      self.database = COUCHDB_SERVER.database(db)
    end
    
    def self.unadorned_database_name
      database.name.sub(/^#{COUCHDB_CONFIG[:db_prefix]}/, '').sub(/#{COUCHDB_CONFIG[:db_suffix]}$/, '')
    end

    def self.search(index, query, options={})
      options[:include_docs] = true
      ret = self.database.search(self.to_s, index, query, options)
      ret['rows'].collect!{|r| self.new(r['doc'])}
      ret
    end

    def only(*whitelist)
      self.class.new.tap do |h|
        (keys & whitelist).each { |k| h[k] = self[k] }
      end
    end

    def except(*blacklist)
      self.class.new.tap do |h|
        (keys - blacklist).each { |k| h[k] = self[k] }
      end
    end
  end
end
