#!/bin/bash


#some imdb data as xml grabbed from: http://community.mediabrowser.tv/permalinks/4117/imdbrating-from-mymovies-xml
PAYLOAD="
<Title>
  <LocalTitle>22 Bullets</LocalTitle>
  <OriginalTitle>L'immortel</OriginalTitle>
  <SortTitle>22 Bullets</SortTitle>
  <Added>16.9.2010 21:15:02</Added>
  <ProductionYear>2010</ProductionYear>
  <RunningTime>117</RunningTime>
  <IMDBrating>6,6</IMDBrating>
  <MPAARating>NR</MPAARating>
  <Description>Charly Matte� has turned a new leaf on his past as an outlaw. Since three years he's living a comfortable life and devoting himself to his wife and two kids. However, one winter morning, he's left for dead in the underground parking of Marseille's Old Port with 22 bullets in his body. Against all odds, he will not die.</Description>
  <Type>XviD</Type>
  <AspectRatio />
  <LockData>False</LockData>
  <IMDB>tt1167638</IMDB>
  <TMDbId>37645</TMDbId>
  <Genres>
    <Genre>Action</Genre>
    <Genre>Crime</Genre>
    <Genre>Thriller</Genre>
  </Genres>
  <Persons>
    <Person>
      <Name>Jean Reno</Name>
      <Type>Actor</Type>
      <Role>Charly Matteï</Role>
    </Person>
    <Person>
      <Name>Gabriella Wright</Name>
      <Type>Actor</Type>
      <Role>Yasmina Telaa</Role>
    </Person>
    <Person>
      <Name>Richard Berry</Name>
      <Type>Actor</Type>
      <Role>Aurelio Rampoli</Role>
    </Person>
    <Person>
      <Name>Kad Merad</Name>
      <Type>Actor</Type>
      <Role>Tony Zacchia</Role>
    </Person>
    <Person>
      <Name>Marina Foïs</Name>
      <Type>Actor</Type>
      <Role>Marie Goldman</Role>
    </Person>
    <Person>
      <Name>Fani Kolarova</Name>
      <Type>Actor</Type>
      <Role>Christelle Mattei</Role>
    </Person>
    <Person>
      <Name>Jean-Pierre Darroussin</Name>
      <Type>Actor</Type>
      <Role>Martin Beaudinard</Role>
    </Person>
    <Person>
      <Name>Claude Gensac</Name>
      <Type>Actor</Type>
      <Role>Mme Fontarosa</Role>
    </Person>
    <Person>
      <Name>Joséphine Berry</Name>
      <Type>Actor</Type>
      <Role>Eva</Role>
    </Person>
    <Person>
      <Name>Venantino Venantini</Name>
      <Type>Actor</Type>
      <Role>Padovano</Role>
    </Person>
    <Person>
      <Name>Moussa Maaskri</Name>
      <Type>Actor</Type>
      <Role>Karim</Role>
    </Person>
    <Person>
      <Name>Daniel Lundh</Name>
      <Type>Actor</Type>
      <Role>Malek Telaa</Role>
    </Person>
    <Person>
      <Name>Denis Braccini</Name>
      <Type>Actor</Type>
      <Role>Le Boumian</Role>
    </Person>
    <Person>
      <Name>Catherine Samie</Name>
      <Type>Actor</Type>
      <Role>Stella Matteï</Role>
    </Person>
    <Person>
      <Name>Joey Starr</Name>
      <Type>Actor</Type>
      <Role>Le Pistachier</Role>
    </Person>
    <Person>
      <Name>Jessica Forde</Name>
      <Type>Actor</Type>
      <Role>Clothilde</Role>
    </Person>
    <Person>
      <Name>Dominique Thomas</Name>
      <Type>Actor</Type>
      <Role>Papalardo</Role>
    </Person>
    <Person>
      <Name>Philippe Magnan</Name>
      <Type>Actor</Type>
      <Role>Pothey</Role>
    </Person>
    <Person>
      <Name>Max Baissette De Malglaive</Name>
      <Type>Actor</Type>
      <Role>Anatole Matteï</Role>
    </Person>
    <Person>
      <Name>Lucie Phan</Name>
      <Type>Actor</Type>
      <Role>Pat</Role>
    </Person>
    <Person>
      <Name>Carlo Brandt</Name>
      <Type>Actor</Type>
      <Role>Fontarosa</Role>
    </Person>
    <Person>
      <Name>Luc Palun</Name>
      <Type>Actor</Type>
      <Role>Pascal Vasetto</Role>
    </Person>
    <Person>
      <Name>Guillaume Gouix</Name>
      <Type>Actor</Type>
      <Role>Le Morvelous</Role>
    </Person>
    <Person>
      <Name>Martial Bezot</Name>
      <Type>Actor</Type>
      <Role>Frank Rabou</Role>
    </Person>
    <Person>
      <Name>Cédric Appietto</Name>
      <Type>Actor</Type>
      <Role>Marco Echinard</Role>
    </Person>
    <Person>
      <Name>Boris Baum</Name>
      <Type>Actor</Type>
      <Role>Spontini - Fils</Role>
    </Person>
    <Person>
      <Name>Jean-Jérôme Esposito</Name>
      <Type>Actor</Type>
      <Role>Rochegude</Role>
    </Person>
    <Person>
      <Name>Charlotte Marcoueille</Name>
      <Type>Actor</Type>
      <Role>Serveuse Restaurant</Role>
    </Person>
    <Person>
      <Name>Laurent Casanova</Name>
      <Type>Actor</Type>
      <Role>Piéton</Role>
    </Person>
    <Person>
      <Name>Richard Berry</Name>
      <Type>Director</Type>
      <Role />
    </Person>
  </Persons>
  <Studios>
    <Studio>Europa Corp.</Studio>
    <Studio>TF1 Films Production</Studio>
    <Studio>Marie Coline Films</Studio>
    <Studio>SMTS</Studio>
    <Studio>Canal+</Studio>
    <Studio>CinéCinéma</Studio>
    <Studio>Sofica Europacorp</Studio>
  </Studios>
  <VideoAspect>2.35:1</VideoAspect>
  <VideoBitrate>1180</VideoBitrate>
  <VideoCodec>MPEG-4</VideoCodec>
  <VideoCodecRaw>MPEG4</VideoCodecRaw>
  <VideoFileSize>1260638208</VideoFileSize>
  <VideoHeight>296</VideoHeight>
  <VideoLength>117</VideoLength>
  <VideoQuality>Standard</VideoQuality>
  <VideoWidth>720</VideoWidth>
  <AudioBitrate>256</AudioBitrate>
  <AudioChannels>5.1</AudioChannels>
  <AudioCodec>AC3</AudioCodec>
  <AudioCodecRaw>AC3</AudioCodecRaw>
  <AudioFrequency>48000</AudioFrequency>
  <VideoHasSubtitles>False</VideoHasSubtitles>
  <IMDbId>tt1167638</IMDbId>
  <Budget>24000000</Budget>
  <Revenue></Revenue>
  <Rating>6,6</Rating>
</Title>
";

#build a larger values payload
CHARLIMIT=1000;
VALUES='';
CVALUES='';
PAYLOAD=${PAYLOAD:0:${CHARLIMIT}} #trim the string to fit the field
for i in {1..20}; do
  VALUES+="(\"${PAYLOAD}\"),";
  CVALUES+="(COMPRESS(\"${PAYLOAD}\")),";
done
VALUES+="(\"${PAYLOAD}\")";
CVALUES+="(COMPRESS(\"${PAYLOAD}\"))";

echo '' > ./adventures_in_archiving_data.sql

for i in non_compressed_data compressed_row compressed_data archive_table tokudb_lzma tokudb_quicklz tokudb_zlib; do
  if [ "$i" != "tokudb_lzma" ] && [ "$i" != "tokudb_quicklz" ] && [ "$i" != "tokudb_zlib" ];
  then
      echo "ALTER TABLE ${i} DISABLE KEYS;" >> adventures_in_archiving_data.sql
  fi
  if [ "$i" != "archive_table" ];
  then
      #disable auto commit for faster imports
      echo "SET AUTOCOMMIT = 0;" >> adventures_in_archiving_data.sql;
  fi
  for j in {1..50000}; do
    if [ "$i" == "compressed_data" ];
    then
      echo "INSERT INTO compressed_data (dat) VALUES ${CVALUES};" >> adventures_in_archiving_data.sql;
    else
      echo "INSERT INTO ${i} (dat) VALUES ${VALUES};" >> adventures_in_archiving_data.sql
    fi
  done
  if [ "$i" != "archive_table" ];
  then
    #commit as one set
    echo "COMMIT;" >> adventures_in_archiving_data.sql;
  fi
  if [ "$i" != "tokudb_lzma" ] && [ "$i" != "tokudb_quicklz" ] && [ "$i" != "tokudb_zlib" ];
  then
      echo "ALTER TABLE ${i} ENABLE KEYS;" >> adventures_in_archiving_data.sql
  fi
  echo "Data gen for ${i} completed"
done
