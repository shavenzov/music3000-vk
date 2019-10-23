package com.audioengine.sources
{
	import flash.net.URLRequest;

	public class SourceManager
	{
		public static function getAudioDataSourceByFileExt( url : String, id : String, bpm : Number, loop : Boolean ) : IAudioDataSource
		{
			var ext : String = url.substring( url.lastIndexOf( "." ) + 1, url.length );
			trace( ext );
			switch( ext )
			{
				case 'mp3'  : return new MPEGSource( new URLRequest( url ), id, bpm, loop );
				
				case 'wav'  : 
				case 'wave' : return new WAVESource( new URLRequest( url ), id, bpm, loop );
					
				case 'aif'  :
				case 'aiff' : return new AIFFSource( new URLRequest( url ), id, bpm, loop );
					
				default : throw new Error( 'Not supported file extension ' + ext, 1000 );	
					
			}
			
			return null;	
		}	
	}
}