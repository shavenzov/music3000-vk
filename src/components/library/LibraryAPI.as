package components.library
{
	import classes.BaseDescription;
	import classes.Sources;
	import classes.api.Call;
	import classes.api.CustomEventDispatcher;
	
	import components.library.events.DataEvent;
	
	public class LibraryAPI extends CustomEventDispatcher
	{
		public function LibraryAPI()
		{
			super();
		}
		
		protected function onDataResult( responds : Object, call : Call ) : void
		{
			if ( responds == null )
			{	
				dispatchEvent( new DataEvent( DataEvent.DATA_COMPLETE, new Vector.<BaseDescription>(), 0 ) );
				return;
			}
			
			var data : Vector.<BaseDescription> = new Vector.<BaseDescription>( responds.data.length );
			
			for ( var i : int = 0; i < responds.data.length; i ++ )
			{
				data[ i ] = Sources.loadFromSource( responds.data[ i ] );
			}
			
			dispatchEvent( new DataEvent( DataEvent.DATA_COMPLETE, data, responds.hasOwnProperty( 'count' ) ? responds.count : responds.data.length ) );	
		}
	}
}