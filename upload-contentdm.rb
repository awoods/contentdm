#!/usr/bin/ruby -w

require "net/http"
require "uri"
require 'nokogiri'

class ContentDMUploader

  def upload(file, host)

    xmlDoc = Nokogiri::XML(File.open(file))

    # Get DOCTYPE
    doctype = xmlDoc.internal_subset

    # Loop descriptions
    descriptions = xmlDoc.xpath("//rdf:Description")

    descriptions.each { |desc| 

      # Get root element
      root = xmlDoc.xpath("//rdf:RDF")
      root.children.remove

      # The top-level XML document
      xml = Nokogiri::XML root.to_xml

      # Add OWL namespace
      owlNS = xml.root.add_namespace_definition('owl', 
                            'http://www.w3.org/2002/07/owl#')
      xml.create_internal_subset(doctype.name, nil, doctype.system_id)

      # What is the original resource?
      about = desc.delete('about')
      puts "processing: #{about}"     
 
      node = xml.create_element('sameAs')
      node.namespace = owlNS
      node.content = about.content

      # About current resource
      desc['about'] = ""

      desc.add_child(node)
      xml.root.add_child(desc.to_xml)

      # Ingest the updated resource
      postResource(host, xml) 
    }

  end

  def postResource(url, body)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request_post(uri.request_uri, 
                                 body.to_xml, 
                                 "Content-Type" => "application/rdf+xml")
    # User feedback
    puts response.body
  end
end

uploader = ContentDMUploader.new
uploader.upload(ARGV[0], "http://localhost:8080/fcrepo/rest")

