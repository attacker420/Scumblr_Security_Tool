#
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

class SearchProvider::FourChan < SearchProvider::Provider
  def self.provider_name
    "4chan Search"
  end

  def self.options
    {
      :board=>{name: "Search specific board", description: "Search a specific board within 4chan for this query (or else board = b (random))", required: false}
    }
  end

  def self.description
    "Search 4chan and create results"
  end

  def initialize(query, options={})
      super
        @options[:board] = @options[:board].blank? ? 'b' : @options[:board]
  end

  def run
    url = URI.escape('https://a.4cdn.org/' + @options[:board] + '/catalog.json')

    response = Net::HTTP.get_response(URI(url))
    results = []
    if response.code == "200"
      search_results = JSON.parse(response.body)
      if (@query.blank?)
        search_results.each do |a|
          a['threads'].each do |b|
            link = "http://boards.4chan.org/" + @options[:board] + "/thread/" + b['no'].to_s
            results <<
            {
              :title => b['filename'],
              :url => link,
              :comment => b['com'],
              :domain => "4chan.org"
            }
          end
        end
      else
        search_results.each do |c|
          c['threads'].each do |d|
            link = "http://boards.4chan.org/" + @options[:board] + "/thread/" + d['no'].to_s
            x = d['com']
            if x[@query]
              results <<
              {
                :title => d['filename'],
                :url => link,
                :comment => d['com'],
                :domain => "4chan.org"
              }
            end
          end
        end
      end
    end
    return results
  end
end
