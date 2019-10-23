package components.library.acapellas
{
	import components.library.PagedList;
	import components.library.acapellas.AcapellaAPI;
	import components.library.events.AssyncItemError;
	import components.library.events.DataEvent;
	import components.library.events.ItemPendingError;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import mx.core.mx_internal;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.utils.ObjectUtil;
	
	use namespace mx_internal;
	
	public class AsyncAcapellaCollection extends PagedList
	{
		private static const MAX_REQUESTS : uint = 2;
		
		private var api : AcapellaAPI;
		
		private var searchParams : Object;
		private var dataLoading : Boolean;
		
		/**
		 * Флаг сброса длины данных 
		 */		
		private var resetData : Boolean;
		
		/**
		 * Запросы стоящие в очереди и ожидающие своего исполнения 
		 */		
		private const waitingRequests : Vector.<Object> = new Vector.<Object>();
		
		/**
		 * Подгружать данные которые отсутствуют 
		 */		
		public var autoUpdate : Boolean = true;
		
		public function AsyncAcapellaCollection( _api : AcapellaAPI = null )
		{
			super( 0, AcapellaAPI.DEFAULT_PAGE_SIZE );
			
			if ( _api ) api = _api;
			 else api = new AcapellaAPI();
			
			api.addListener( DataEvent.DATA_COMPLETE, onSearchResult, this );
			//api.addListener( ErrorEvent.ERROR, onSearchFault, this );
		}
		
		private function onSearchResult( e : DataEvent ) : void
		{
			if ( resetData )
			{
				data = Vector.<Object>( e.data );
				
				data.length = e.count;
				resetData = false;
				
				dispatchEvent( new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.RESET ) );
				dispatchEvent( e );
			}
			else
			{
				storeItemsAt( Vector.<Object>( e.data ), searchParams.offset );
			}	
				
		    checkNextRequest();
		}
		/*
		private function onSearchFault( e : ErrorEvent ) : void
		{
			if ( resetData )
			{
				dispatchEvent( e );
				return;
			}	
			
			resetData = false;
			failItemsAt( searchParams.offset, searchParams.limit );
			dataLoading = false;
			
			checkNextRequest();
		}
		*/
		public function search( params : Object ) : void{
			
			waitingRequests.length = 0;	
			
			searchParams = ObjectUtil.clone( params );
			
			if ( ! searchParams.limit )
			{
				searchParams.limit = pageSize;
			}
			
			resetData = true;
			loadData( searchParams ); 
		}
		
		private function loadData( params : Object) : void
		{
			if ( dataLoading )
			{
				//Если количество ожижающих запросов в стеке == MAX_REQUESTS, то анулируем эти запросы
				if ( waitingRequests.length === MAX_REQUESTS )
				{
					var p : Object = waitingRequests[ 0 ];
					
					waitingRequests.splice( 0, 1 );
					
					// dispatch collection and property change events
					var propertyChangeEvents:Array = new Array( p.limit );  // Array of PropertyChangeEvents; 
					
					for ( var i:int = 0; i < p.limit; i++ )
					{
						var index : int = p.offset + i;
						propertyChangeEvents[ i ] = createUpdatePCE( index, null, data[ index ] );
						data[ index ] = null;
					}	
					
					
					if ( hasEventListener( CollectionEvent.COLLECTION_CHANGE ) )
						dispatchEvent(createCE(CollectionEventKind.REPLACE, p.offset, propertyChangeEvents));
					
					if ( hasEventListener( PropertyChangeEvent.PROPERTY_CHANGE ) )
					{
						for each ( var pce : PropertyChangeEvent in propertyChangeEvents)
						dispatchEvent(pce);
					}
				}	
				
				waitingRequests.push( ObjectUtil.clone( params ) );
				
				return;
			}	
			//trace( 'loading', params.p - 1, ( params.p - 1 ) * pageSize );
			callSearch( params );
		}
		
		private function callSearch( params : Object ) : void
		{
			searchParams = params;
			
			api.search( params );
			dataLoading = true;
			dispatchEvent( new ProgressEvent( ProgressEvent.PROGRESS ) );
		}
		
		private function checkNextRequest() : void
		{
			if ( waitingRequests.length == 0 )
			{
				dataLoading = false;
				dispatchEvent( new Event( Event.COMPLETE ) );
				return;
			}
			
			callSearch( waitingRequests.pop() );
		}
		
		private function calculateParams( page : int ) : Object
		{
			var p : Object = new Object();
			p.pageStartIndex = page * pageSize;
			p.left = length - p.pageStartIndex;
			p.n = ( p.pageStartIndex + pageSize ) > length ? p.left : pageSize;
			
			return p;	
		}
		
		override public function getItemAt(index:int, prefetch:int=0):Object
		{
			//trace( index, length );
			var item       : Object = data[index];
			//var needUpdate : Boolean;
			
			if ( item is AssyncItemError )
			{			
				if ( item.id == 0 )
				{
					item.id = 1;
				}
				else
				{
					item = null;
					//needUpdate = true;
				}
			}
			
			if ( autoUpdate )
			{
				if ( item === null )
				{
					const ipe:ItemPendingError = new ItemPendingError();
					const page : int = Math.floor( index / pageSize );
					const p : Object =  calculateParams( page );
					
					//const propertyChangeEvents:Array = new Array( p.n );
					
					for (var i:int = 0; i < p.n; i++)
					{
						var itemIndex : int = p.pageStartIndex + i;
						
						data[ itemIndex ] = ipe;
						//propertyChangeEvents[ itemIndex ] = createUpdatePCE( index, null, ipe );
					}
					
					const params : Object = ObjectUtil.clone( searchParams );
					params.offset = p.pageStartIndex;
					params.limit = p.n;
					
					loadData( params );
					
					item = data[index];
				}	
			}
			
			return item;
		}
		
		public function updateItems( indexes : Vector.<int> ) : void
		{
			for each( var index : int in indexes )
			getItemAt( index );
		}
	}
}