package components.library.looperman
{
	import classes.api.Call;
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	
	import components.library.LibraryAPI;
	import components.library.looperman.events.TagEvent;
		
	public class LoopermanAPI extends LibraryAPI
	{
		public static const DEFAULT_PAGE_SIZE : int = 20;
		private static const DEFAULT_ORDER_BY  : String = 'date';
		
		private var api : MainAPIImplementation;
		
		public function LoopermanAPI()
		{
			super();
			api = MainAPI.impl;
		}
				
		private function onTagGCResult( responds : Object, call : Call ) : void
		{
			var genres     : Array = responds.genres != undefined     ? Settings.processGenres( responds.genres ) : null;
			var categories : Array = responds.categories != undefined ? Settings.processCategories( responds.categories ) : null;
			var tempos     : Array = responds.tempos != undefined ? responds.tempos : null;
			var keys       : Array = responds.keys != undefined ? responds.keys : null;
			
			dispatchEvent( new TagEvent( TagEvent.TAG_COMPLETE, genres, categories, tempos, keys ) );
		}
		
		public function getSearchParams( params : Object = null, getGenres : Boolean = false, getCategories : Boolean = true, getTempos : Boolean = true, getKeys : Boolean = true ) : void
		{
			api.call( 'Library.getSearchParams', onTagGCResult, params, getGenres, getCategories, getTempos, getKeys );
		}
		
		public function search( params : Object = null ) : void
		{
			api.call( 'Library.search', onDataResult, params );
		}
		
		public function getInfo( ids : Array ) : void
		{
			api.call( 'Library.getInfo', onDataResult, ids );
		}
	}
}
