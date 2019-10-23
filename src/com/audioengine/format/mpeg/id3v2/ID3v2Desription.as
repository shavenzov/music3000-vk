/**
 * The following frames are declared in this draft.

  4.19  AENC Audio encryption
  4.14  APIC Attached picture
  4.30  ASPI Audio seek point index

  4.10  COMM Comments
  4.24  COMR Commercial frame

  4.25  ENCR Encryption method registration
  4.12  EQU2 Equalisation (2)
  4.5   ETCO Event timing codes

  4.15  GEOB General encapsulated object
  4.26  GRID Group identification registration

  4.20  LINK Linked information

  4.4   MCDI Music CD identifier
  4.6   MLLT MPEG location lookup table

  4.23  OWNE Ownership frame

  4.27  PRIV Private frame
  4.16  PCNT Play counter
  4.17  POPM Popularimeter
  4.21  POSS Position synchronisation frame

  4.18  RBUF Recommended buffer size
  4.11  RVA2 Relative volume adjustment (2)
  4.13  RVRB Reverb

  4.29  SEEK Seek frame
  4.28  SIGN Signature frame
  4.9   SYLT Synchronised lyric/text
  4.7   SYTC Synchronised tempo codes

  4.2.1 TALB Album/Movie/Show title
  4.2.3 TBPM BPM (beats per minute)
  4.2.2 TCOM Composer
  4.2.3 TCON Content type
  4.2.4 TCOP Copyright message
  4.2.5 TDEN Encoding time
  4.2.5 TDLY Playlist delay
  4.2.5 TDOR Original release time
  4.2.5 TDRC Recording time
  4.2.5 TDRL Release time
  4.2.5 TDTG Tagging time
  4.2.2 TENC Encoded by
  4.2.2 TEXT Lyricist/Text writer
  4.2.3 TFLT File type
  4.2.2 TIPL Involved people list
  4.2.1 TIT1 Content group description
  4.2.1 TIT2 Title/songname/content description
  4.2.1 TIT3 Subtitle/Description refinement
  4.2.3 TKEY Initial key
  4.2.3 TLAN Language(s)
  4.2.3 TLEN Length
  4.2.2 TMCL Musician credits list
  4.2.3 TMED Media type
  4.2.3 TMOO Mood
  4.2.1 TOAL Original album/movie/show title
  4.2.5 TOFN Original filename
  4.2.2 TOLY Original lyricist(s)/text writer(s)
  4.2.2 TOPE Original artist(s)/performer(s)
  4.2.4 TOWN File owner/licensee
  4.2.2 TPE1 Lead performer(s)/Soloist(s)
  4.2.2 TPE2 Band/orchestra/accompaniment
  4.2.2 TPE3 Conductor/performer refinement
  4.2.2 TPE4 Interpreted, remixed, or otherwise modified by
  4.2.1 TPOS Part of a set
  4.2.4 TPRO Produced notice
  4.2.4 TPUB Publisher
  4.2.1 TRCK Track number/Position in set
  4.2.4 TRSN Internet radio station name
  4.2.4 TRSO Internet radio station owner
  4.2.5 TSOA Album sort order
  4.2.5 TSOP Performer sort order
  4.2.5 TSOT Title sort order
  4.2.1 TSRC ISRC (international standard recording code)
  4.2.5 TSSE Software/Hardware and settings used for encoding
  4.2.1 TSST Set subtitle
  4.2.2 TXXX User defined text information frame

  4.1   UFID Unique file identifier
  4.22  USER Terms of use
  4.8   USLT Unsynchronised lyric/text transcription

  4.3.1 WCOM Commercial information
  4.3.1 WCOP Copyright/Legal information
  4.3.1 WOAF Official audio file webpage
  4.3.1 WOAR Official artist/performer webpage
  4.3.1 WOAS Official audio source webpage
  4.3.1 WORS Official Internet radio station homepage
  4.3.1 WPAY Payment
  4.3.1 WPUB Publishers official webpage
  4.3.2 WXXX User defined URL link frame 
 */
package com.audioengine.converters.encoders.mpeg.id3v2
{
	public class ID3v2Desription
	{
		private static const frameID : Vector.<String> = Vector.<String>(
			[
			  'AENC',
			  'APIC',
			  'ASPI',
			  
			  'COMM',
			  'COMR',
			  
			  'ENCR',
			  'EQU2',
			  'ETCO',
			  
			  'GEOB',
			  'GRID',
			  
			  'LINK',
			  
			  'MCDI', 
			  'MLLT',
			  
			  'OWNE',
			  
			  'PRIV',
			  'PCNT',
			  'POPM',
			  'POSS',
			  
			  'RBUF',
			  'RVA2',
			  'RVRB',
			  
			  'SEEK',
			  'SIGN',
			  'SYLT',
			  'SYTC',
			  
			  'TALB',
			  'TBPM',
			  'TCOM',
			  'TCON',
			  'TCOP',
			  'TDEN',
			  'TDLY',
			  'TDOR',
			  'TDRC',
			  'TDRL',
			  'TDTG',
			  'TENC',
			  'TEXT',
			  'TFLT',
			  'TIPL',
			  'TIT1',
			  'TIT2',
			  'TIT3',
			  'TKEY',
			  'TLAN',
			  'TLEN',
			  'TMCL',
			  'TMED',
			  'TMOO',
			  'TOAL',
			  'TOFN',
			  'TOLY',
			  'TOPE',
			  'TOWN',
			  'TPE1',
			  'TPE2',
			  'TPE3',
			  'TPE4',
			  'TPOS',
			  'TPRO',
			  'TPUB',
			  'TRCK',
			  'TRSN',
			  'TRSO',
			  'TSOA',
			  'TSOP',
			  'TSOT',
			  'TSRC',
			  'TSSE',
			  'TSST',
			  
			  'UFID',
			  'USER',
			  'USLT',
			  
			  'WCOM',
			  'WCOP',
			  'WOAF',
			  'WOAR',
			  'WOAS',
			  'WORS',
			  'WPAY',
			  'WPUB'
			  
			  
			]	
			);
		
		private static const frameDescription : Vector.<String> = Vector.<String>(
			[
			  'Audio encryption',
			  'Attached picture',
			  'Audio seek point index',
			  
			  'Comments',
			  'Commercial frame',
			  
			  'Encryption method registration',
			  'Equalisation (2)',
			  'Event timing codes',
			  
			  'General encapsulated object',
			  'Group identification registration',
			  'Linked information',
			  
			  'Music CD identifier',
			  'MPEG location lookup table',
			  
			  'Ownership frame',
			  
			  'Private frame',
			  'Play counter',
			  'Popularimeter',
			  'Position synchronisation frame',
			  
			  'Recommended buffer size',
			  'Relative volume adjustment (2)',
			  'Reverb',
			  
			  'Seek frame',
			  'Signature frame',
			  'Synchronised lyric/text',
			  'Synchronised tempo codes',
			  
			  'Album/Movie/Show title',
			  'BPM (beats per minute)',
			  'Composer',
			  'Content type',
			  'Copyright message',
			  'Encoding time',
			  'Playlist delay',
			  'Original release time',
			  'Recording time',
			  'Release time',
			  'Tagging time',
			  'Encoded by',
			  'Lyricist/Text writer',
			  'File type',
			  'Involved people list',
			  'Content group description',
			  'Title/songname/content description',
			  'Subtitle/Description refinement',
			  'Initial key',
			  'Language(s)',
			  'Length',
			  'Musician credits list',
			  'Media type',
			  'Mood',
			  'Original album/movie/show title',
			  'Original filename',
			  'Original lyricist(s)/text writer(s',
			  'Original artist(s)/performer(s)',
			  'File owner/licensee',
			  'Lead performer(s)/Soloist(s)',
			  'Band/orchestra/accompaniment',
			  'Conductor/performer refinement',
			  'Interpreted, remixed, or otherwise modified by',
			  'Part of a set',
			  'Produced notice',
			  'Publisher',
			  'Track number/Position in set',
			  'Internet radio station name',
			  'Internet radio station owner',
			  'Album sort order',
			  'Performer sort order',
			  'Title sort order',
			  'ISRC (international standard recording code)',
			  'Software/Hardware and settings used for encoding',
			  'Set subtitle',
			  
			  'Unique file identifier',
			  'USLT Unsynchronised lyric/text transcription',
			  
			  'Commercial information',
			  'Copyright/Legal information',
			  'Official audio file webpage',
			  'Official artist/performer webpage',
			  'Official audio source webpage',
			  'Official Internet radio station homepage',
			  'Payment',
			  'Publishers official webpage'
			  
			]	
		);
		
		public static function isTextFrame( id : String ) : Boolean
		{
			return id.charAt( 0 ) == 'T'; 
		}
		
		public static function getFrameDescription( id : String ) : String
		{
			var i : int = 0;
			
			while( i < frameID.length )
			{
				if ( frameID[ i ] == id ) return frameDescription[ i ];
				i ++;
			}
			
			return id;
		}	
	}
}