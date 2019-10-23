package classes
{
	public dynamic class SampleDescription extends BaseDescription
	{
		public function SampleDescription( id : String, hqurl : String, lqurl : String, name : String, author : String, duration : Number, bpm : Number, key : String, genre : String, category : String, 
		                                   loop : Boolean, favorite : Boolean )
		{
		  super( id, hqurl, lqurl, name, author, duration, bpm, key, genre, category, loop, favorite );
		}
		
		public static function loadFromSource( data : Object ) : SampleDescription
		{	
			var loop : Boolean = ( data.category != 'Fx Loops') && ( data.category != 'Vocal Loops' );
				
			return new SampleDescription( BaseDescription.serializeSampleID( data.hash, Sources.SAMPLE_SOURCE ), data.hqurl, data.lqurl, data.name, data.author, data.duration, data.tempo, data.mkey, data.genre, data.category, loop, data.favorite ); 	
		}
	}
}