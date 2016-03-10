#     Contributions by Nick Kleck
#         APTNotes search provider created by Nick Kleck
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

class SearchProvider::APTnotes < SearchProvider::Provider
  def self.provider_name
    "APTnotes Search"
  end

  def self.options
    {}
  end

  def initialize(query, options={})
    super
  end

  def run
    url = URI.escape('https://aptnotes.malwareconfig.com/ioc_export.json')

    response = Net::HTTP.get_response(URI(url))
    results = []
    if response.code == "200"
      data = response.body
      data.gsub!('}', '},').prepend("[")
      data2 = data.reverse.sub!(',', '').reverse + "]"
      search_results = JSON.parse(data2)
      if (@query.blank?)
        search_results.each do |a|
          link = a['path'].gsub!('/var/www/aptnotes', 'https://aptnotes.malwareconfig.com/web/viewer.html?file=..')
          results <<
          {
            :title => a['match'],
            :url => link,
            :type => a['type'],
            :domain => "aptnotes.malwareconfig.com"
          }
        end
      else
        search_results.each do |b|
          link = b['path'].gsub!('/var/www/aptnotes', 'https://aptnotes.malwareconfig.com/web/viewer.html?file=..')
          x = b['match']
          if x[@query]
            results <<
            {
              :title => b['match'],
              :url => link,
              :type => b['type'],
              :domain => "aptnotes.malwareconfig.com"
            }
          end
        end
      end
    end
    return results
  end
end
