#     Contributions by Nick Kleck
#         8ch search provider
#
#     Copyright 2014 Netflix, Inc.        
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.

require 'uri'
require 'net/http'
require 'json'

class SearchProvider::EightChan < SearchProvider::Provider
  def self.provider_name
    "8ch Search"
  end

  def self.options
    {
      :board=>{name: "Search specific board", description: "Search a specific board within 4chan for this query (or else board = b (random))", required: false}
    }
  end

  def initialize(query, options={})
      super
        @options[:board] = @options[:board].blank? ? 'b' : @options[:board]
  end

  def run
    url = URI.escape('https://8ch.net/' + @options[:board] + '/catalog.json')

    response = Net::HTTP.get_response(URI(url))
    results = []
    if response.code == "200" 
      search_results = JSON.parse(response.body)
      if (@query.blank?)
        search_results.each do |a|
          a['threads'].each do |b|
            link = "https://8ch.net/" + @options[:board] + "/res/" + b['no'].to_s + '.html'
            results <<
            {
              :title => b['filename'],
              :url => link,
              :comment => b['com'],
              :domain => "8ch.net"
            }
          end
        end
      else
        search_results.each do |c|
          c['threads'].each do |d|
            link = "https://8ch.net/" + @options[:board] + "/res/" + d['no'].to_s + '.html'
            x = d['com']
            if x[@query]
              results <<
              {
                :title => d['filename'],
                :url => link,
                :comment => d['com'],
                :domain => "8ch.net"
              }
            end
          end
        end
      end
    end
    return results
  end
end
