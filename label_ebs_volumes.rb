#!/usr/bin/ruby

require 'rubygems'
require 'yaml'
require 'json'
require 'fog'

#Fetch AWS instance details for a given region.
def getServerVols(fogo=nil)
  return {} if fogo.nil?
  slist=Hash.new
  icount=0
  fogo.servers.all.each do |i|
    icount+=1
    #Flatten list to be able to locate by volid
    i.block_device_mapping.each do |thisdisk|
      slist [ thisdisk['volumeId'] ] = {
          'deviceName'=> thisdisk['deviceName'],
          'instance-id' => i.id,
          'server-name' => i.tags['Name']
      }
    end
  end
  puts "Found #Servers=#{icount} with Volumes=#{slist.keys.length}"
  return slist
end


creds=Hash.new

begin
  creds=YAML::load(File.open("./auth.yml"))
rescue Exception => e
  abort "Error fetching AWS auth info - #{e.inspect}"
end


abort "No regions specified in config." unless (creds.has_key?(:regions) && creds[:regions].length > 0)

creds[:regions].sort.each do |thisregion|
  puts "Working on region #{thisregion.upcase}"

  fogobj = Fog::Compute.new(
    :provider => 'AWS', 
    :region => thisregion, 
    :aws_access_key_id => creds[:aws_access_key_id],
    :aws_secret_access_key => creds[:aws_secret_access_key]
  )

  vols=fogobj.volumes.all
  attachmentinfo=getServerVols(fogobj)
  
  vols.each do |thisvol|
    name=thisvol.tags['Name'] || nil
    if name.nil?
      taghash=Hash.new
      #Set name from association when available
      if attachmentinfo.has_key?(thisvol.id)
        iname=attachmentinfo[thisvol.id]['instance-id']
        sname=attachmentinfo[thisvol.id]['server-name'] 
        dname=attachmentinfo[thisvol.id]['deviceName']
        name=sname.nil? ? "Instance #{iname} Dev #{dname}": "Server #{sname} (#{iname}) Dev #{dname}"
        taghash={'Name'=>name, 'NameTagUpdatedAt' => "#{Time.now.to_i}" }
      else
        taghash={'Name'=>"Unassociated as of #{Time.now.to_s}" }
      end
      taghash['Creator']=ENV['USER']+' from '+Socket.gethostname
      puts "Volume #{thisvol.id} => Set to [ #{taghash['Name']} ]"
      taghash.keys.each do |x|
        puts "\tSET_TAG: #{x} => #{taghash[x]}"
        fogobj.tags.create :key => x, :value => taghash[x], :resource_id => thisvol.id
      end 
    else
      puts "Volume #{thisvol.id} - NOP at [#{name}]"
    end 
  end
  puts '----'
end
