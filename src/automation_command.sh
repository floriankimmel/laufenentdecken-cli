episode=${args[--m4a]}
skipFtp=${args[--skip-ftp]}
skipAws=${args[--skip-aws]}
skipAuphonic=${args[--skip-auphonic]}
skipPatreon=${args[--skip-patreon]}
skipBlogpost=${args[--skip-blogpost]}

read -p "Episode Nummer: " postNumber
read -p "Episode Titel: " postTitle
read -p "Release (YYYY-MM-DD): " postDate

title=$(echo "$episode" | cut -d'.' -f 1)
chapters=$(<"$title".chapters.txt)
cover="$title".png

episode_patreon="$title"_patreon.m4a
title_patreon="$title"_patreon

coverYoutube="$title"_youtube.png
baseUrl="https://rssfeed.laufendentdecken-podcast.at/data/"

coverUrl="$baseUrl$cover"
coverUrlYoutube="$baseUrl$coverYoutube"

sudo=$(op item get "sudo" --format json | jq -r '. | .fields | .[] | select(.label=="password") | .value')

if [[ -z "$skipFtp" ]]; then
    echo
    echo "Upload episode to FTP Server"
    lep ftp --file $episode
    echo "Upload patreon episode to FTP Server"
    lep ftp --file $episode_patreon
    echo "Upload cover to FTP Server"
    lep ftp --file $cover
    echo "Upload youtube cover to FTP Server"
    lep ftp --file $coverYoutube 
fi

if [[ -z "$skipAws" ]]; then
    echo
    echo "Backup to S3"

    aws s3 cp $episode s3://laufendentdecken-podcast/
    aws s3 cp s3://laufendentdecken-podcast/$episode s3://laufendentdecken-podcast-backup/

    aws s3 cp $episode_patreon s3://laufendentdecken-podcast/
    aws s3 cp s3://laufendentdecken-podcast/$episode_patreon s3://laufendentdecken-podcast-backup/
fi

if [[ -z "$skipAuphonic" ]]; then
    episodePreset = "WbQunVJaZFitr3z74XTyxJ" 
    youtubePreset = "M9ageytQCjaFAYn7EjSYPZ" 
    lep auphonic  \
        --production_name $title \
        --preset $episodePreset\
        --cover_url $coverUrl \
        --file $episode \
        --slug $title

    lep auphonic  \
        --production_name "LEP#$postNumber - $postTitle" \
        --preset $youtubePreset \
        --cover_url $coverUrlYoutube \
        --file $episode \
        --slug $title

    lep auphonic  \
        --production_name "$title (Patreon/Steady)" \
        --preset $episodePreset \
        --cover_url $coverUrl \
        --file $episode_patreon \
        --slug $title
    echo "Podcast successfully uploaded"
fi


if [[ -z "$skipPatreon" ]]; then
    echo
    echo "Download Patreon again to be able to upload it to the server"
    curl https://rssfeed.laufendentdecken-podcast.at/data/$title_patreon.mp3 --output ~/Downloads/$title_patreon.mp3
fi

if [[ -z "$skipBlogpost" ]]; then
    echo
    echo "Create Episode on Website"

    lep blogpost \
        --number $postNumber \
        --title $postTitle \
        --publish_date $postDate \
        --slug $title

fi

