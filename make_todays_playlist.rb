require 'google/api_client'
require 'active_support/all'
# The oauth/oauth_util code is not part of the official Ruby client library. 
# Download it from:
# http://samples.google-api-ruby-client.googlecode.com/git/oauth/oauth_util.rb
require_relative "oauth_util"


# This OAuth 2.0 access scope allows for full read/write access to the
# authenticated user's account.
YOUTUBE_SCOPE = 'https://www.googleapis.com/auth/youtube'
YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'

client = Google::APIClient.new({
  application_name: "uzimy-libyoutube",
  application_version: "v0.0.1"
})

youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)

auth_util = CommandLineOAuthHelper.new(YOUTUBE_SCOPE)
client.authorization = auth_util.authorize()

# Call the API's youtube.subscriptions.insert method to add the subscription
# to the specified channel.


channels = {
  "VOA Learning English" => "UCKyTokYo0nK2OA-az-sDijA",
  "CNN"                  => "UCupvZG-5ko_eiXAupbDfxWw",
}

begin
  puts "gether today's video"
  today_videos = channels.map { |title,channel_id|
    res = client.execute!(
      api_method: youtube.search.list,
      parameters: {
        part: "snippet",
        maxResults: 50,
        channelId: channel_id,
        order: "date",
      },
    )
    res.data.items.select {|i| i.snippet.published_at > 1.day.ago}.map {|i| [i.snippet.title, i.id.video_id]}
  }.flatten(1).to_h

  puts "create playlist"
  res = client.execute!(
    api_method: youtube.playlists.insert,
    parameters: {
      part: "snippet"
    },
    body_object: {
      snippet: {
        title: "Today's News (#{Date.today.to_s})"
      }
    }
  )
  playlist_id = res.data.id
  puts "created:  id #{playlist_id}"

  puts "insert the videos"
  today_videos.each do |title,video_id|
    puts "#{playlist_id} => #{title}:#{video_id}"
    body = {
      playlistId: playlist_id,
      resouceId: {
        kind: "youtube#video",
        videoId: video_id
      }
    }
    p body
    res = client.execute!(
      api_method: youtube.playlist_items.insert,
      parameters: {
        part: "snippet"
      },
      body_object: {
        snnipet: {
          playlistId: playlist_id,
          resouceId: {
            kind: "youtube#video",
            videoId: video_id
          }
        }
      }
    )
    p res.data.snnipet
  end
rescue Google::APIClient::ClientError => e
  puts "error: #{e}"
end
