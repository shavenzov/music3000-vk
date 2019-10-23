package components.library.freesound
{
	import components.library.PagedList;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import mx.collections.errors.ItemPendingError;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.freesound.SoundCollection;

	public class AsyncSoundCollection extends PagedList
	{
		private static const MAX_REQUESTS : uint = 2;
		
		private var sc : SoundCollection;
		private var _params : Object;
		
		/**
		 * Подгружаются ли в данный момент данные или нет 
		 */		
		private var _loading : Boolean;
		
		/**
		 * Запросы стоящие в очереди и ожидающие своего исполнения 
		 */		
		private const waitingRequests : Vector.<Object> = new Vector.<Object>();
		
		/**
		 * Вкл/выкл подгрузка данных
		 */		
		public var disabled : Boolean;
		
		private static function cloneObject( obj : Object ) : Object
		{
			var result : Object = new Object();
			
			for ( var prop : String in obj )
			{ 
			result[ prop ] = obj[ prop ];
			}
			return result 
		}	
		
		public function AsyncSoundCollection( pageSize : int = 30 )
		{
			super( 0, pageSize );
			
			sc = new SoundCollection();
			sc.addEventListener( "GotSoundCollection", onGotSoundCollection );
			sc.addEventListener( FaultEvent.FAULT, onFault );	 
		}
		
		public function getSoundsFromQuery( params : Object ) : void
		{
			_params = params;
			_params.p = 1;
			_params.sounds_per_page = pageSize;
			
			length = 0;
			waitingRequests.length = 0;
			_loading = false;
			
			loadPage( _params );
		}	
		
		private function loadPage( params : Object ) : void
		{
			//trace( 'try to loading', params.p, ( params.p - 1 ) * pageSize );
			
			if ( _loading )
			{
				//Если количество ожижающих запросов в стеке == MAX_REQUESTS, то анулируем эти запросы
				if ( waitingRequests.length === MAX_REQUESTS )
				{
					var p : Object = calculateParams( waitingRequests[ 0 ].p - 1 );
					
					waitingRequests.splice( 0, 1 );
					
					// dispatch collection and property change events
					var propertyChangeEvents:Array = new Array( p.n );  // Array of PropertyChangeEvents; 
					
					for ( var i:int = 0; i < p.n; i++ )
					{
						var index : int = p.pageStartIndex + i;
						propertyChangeEvents[ i ] = createUpdatePCE( index, null, data[ index ] );
						data[ index ] = null;
					}	
						
					
					if ( hasEventListener( CollectionEvent.COLLECTION_CHANGE ) )
						dispatchEvent(createCE(CollectionEventKind.REPLACE, p.pageStartIndex, propertyChangeEvents));
					
					if ( hasEventListener( PropertyChangeEvent.PROPERTY_CHANGE ) )
					{
						for each ( var pce : PropertyChangeEvent in propertyChangeEvents)
						dispatchEvent(pce);
					}
				}	
				
				waitingRequests.push( cloneObject( params ) );
				
				return;
			}	
			//trace( 'loading', params.p - 1, ( params.p - 1 ) * pageSize );
			
			_params = params;
			sc.getSoundsFromQuery( params );
			_loading = true;
			dispatchEvent( new Event( ProgressEvent.PROGRESS ) );
		}	
		
		private function checkNextRequest() : void
		{
			if ( waitingRequests.length == 0 )
			{
				_loading = false;
				dispatchEvent(  new Event( Event.COMPLETE ) );
				return;
			}
			
			_params = waitingRequests.pop();
			
			//trace( 'loading', _params.p - 1, ( _params.p - 1 ) * pageSize );
			sc.getSoundsFromQuery( _params );
			dispatchEvent( new Event( ProgressEvent.PROGRESS ) );
		}	
		
		private function onGotSoundCollection( e : ResultEvent ) : void
		{
		  //trace( 'loaded', sc.current_page - 1, ( sc.current_page - 1 ) * pageSize );
			
		  if ( length == 0 )
		  {
			  length = sc.num_results;
		  }
		  
		  storeItemsAt( Vector.<Object>( sc.soundList ), ( sc.current_page - 1 ) * pageSize );
		  
		  checkNextRequest();
		}
		
		private function calculateParams( page : int ) : Object
		{
			var p : Object = new Object();
			    p.pageStartIndex = page * pageSize;
				p.left = length - p.pageStartIndex;
				p.n = ( p.pageStartIndex + pageSize ) > length ? p.left : pageSize;
				
			return p;	
		}	
		
		private function onFault( e : FaultEvent ) : void
		{
			trace( 'Error while fetching data from freesound api' );
			
			var p : Object = calculateParams( _params.p );
			
			failItemsAt( p.pageStartIndex, p.n ); 
			checkNextRequest();
		}
		
		override public function getItemAt(index:int, prefetch:int=0):Object
		{
			checkItemIndex(index, length);
			//trace( index, length );
			var item:* = data[index];
			
			if ( disabled || ( item is ItemPendingError ) )
			{
				throw item as ItemPendingError;
			}
			else if ( ( item === null ) && ( length > 0 ) )
			{
				const ipe:ItemPendingError = new ItemPendingError(String(index));
				const page : int = Math.floor( index / pageSize );
				const p : Object = calculateParams( page );
				
				for (var i:int = 0; i < p.n; i++)
					data[p.pageStartIndex + i] = ipe;
				
				const params : Object = cloneObject( _params );
				      params.p = page + 1;
				
				loadPage( params );
				
				// Allow for the possibility that loadItemsFunction has synchronously
				// loaded the requested data item.
				
				if (data[index] == ipe)
					throw ipe;
				else
					item = data[index];
			}
			
			return item;
		}
	}
}