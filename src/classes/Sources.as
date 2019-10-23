package classes
{
	public class Sources
	{
		public static const SAMPLE_SOURCE    : String = 'MAIN';
		public static const ACAPELLA_SOURCE  : String = 'ACAP';
		
		public static function loadFromSource( data : Object ) : BaseDescription
		{
			if ( data.source_id == undefined )
			  throw new Error( 'Samples source_id not set', 100 );
			
			if ( data.source_id == SAMPLE_SOURCE )
			{
				return SampleDescription.loadFromSource( data );
			}
			
			if ( data.source_id == ACAPELLA_SOURCE )
			{
				return AcapellaDescription.loadFromSource( data );
			}
			
			throw new Error( 'Unknown source id ' + data.source_id, 250 );
			
			return null;
		}
	}
}