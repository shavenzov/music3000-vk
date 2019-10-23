package com.dataloaders
{
	import classes.api.CustomEventDispatcher;
	
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	
	public class DataLoader extends CustomEventDispatcher
	{
		protected var MAX_PARALLEL_REQUESTS : uint;
		
		protected var inqueue : Vector.<LoaderRecord> = new Vector.<LoaderRecord>();
		protected var loading : Vector.<LoaderRecord> = new Vector.<LoaderRecord>();
		
		protected var _busy : Boolean;
		
		public function DataLoader( MAX_PARALLEL_REQUESTS : uint = 6 )
		{
			super();
			this.MAX_PARALLEL_REQUESTS = MAX_PARALLEL_REQUESTS;
		}
		
		public function get busy() : Boolean
		{
			return _busy;
		}
		
		protected function isObjectLoading( data : Object ) : Boolean
		{
			return ( getObjectIndex( inqueue, data ) != -1 ) || ( getObjectIndex( loading, data ) != -1 );
		}
		
		protected function getRecordIndexByLoader( list : Vector.<LoaderRecord>, loader : Object ) : int
		{
			for ( var i : int = 0; i < list.length; i ++ )
			{
				if ( list[ i ].loader == loader )
				{
					return i;
				}	
			}	
			
			return -1;
		}	
		
		protected function getObjectIndex( list : Vector.<LoaderRecord>, data : Object ) : int
		{
			for ( var i : int = 0; i < list.length; i ++ )
			{
				if ( list[ i ].data == data )
				{
					return i;
				}	
			} 
			
			return -1;
		}	
		
		protected function getObjectIndexes( list : Vector.<LoaderRecord>, data : Object ) : Vector.<int>
		{
			var result : Vector.<int> = new Vector.<int>();
			
			for ( var i : int = 0; i < list.length; i ++ )
			{
				if ( list[ i ].data == data )
				{
					result.push( i );
				}	
			}	
			
			return result.length > 0 ? result : null;
		}
		
		/**
		 * Убирает все запросы из очереди ассоциированные с данными 
		 * @param s
		 * 
		 */		
		protected function cancelRequestInLists( data : Object, lists : Vector.<Vector.<LoaderRecord>>, callClose : Boolean = false ) : Boolean
		{
			var result : Boolean = false;
			
			for each( var list : Vector.<LoaderRecord> in lists )
			{
				var indexes : Vector.<int> = getObjectIndexes( list, data );
				var index   : int;
				
				if ( indexes )
				{
					for( index = indexes.length - 1; index >= 0; index -- )
					{	
						if ( callClose )
						{
							list[ index ].loader.close();
							releaseListeners( list[ index ].loader );
						}
						
						list.splice( index, 1 );	
					}
					
					result = true;
				}
			}
			
			return result;
		}
		
		/**
		 * Останавливает запросы ожидающие исполнения 
		 * @param data
		 * @return 
		 * 
		 */		
		public function cancel( data : Object ) : Boolean
		{
		  return cancelRequestInLists( data, Vector.<Vector.<LoaderRecord>>( [ inqueue ] ) );
		}
		
		/**
		 * Останавливает любой запрос, даже если он на исполнении 
		 * @param data
		 * @return 
		 * 
		 */		
		public function close( data : Object ) : Boolean
		{
		  return cancelRequestInLists( data, Vector.<Vector.<LoaderRecord>>( [ inqueue, loading ] ), true );	
		}
		
		
		/**
		 * Полностью очищает очередь загрузки 
		 * 
		 */		
		public function clear() : void
		{
			for each( var record : LoaderRecord in loading )
			{
				record.loader.close();
				releaseListeners( record.loader );
			}
			
			inqueue.length = 0;
			loading.length = 0;
			
			_busy = false;
		}	
		
		protected function setListeners( loader : Object ) : void
		{
			loader.addEventListener( Event.COMPLETE, itemComplete ); 
			loader.addEventListener( ProgressEvent.PROGRESS, itemProgress ); 
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, itemSecurityError );
			loader.addEventListener( IOErrorEvent.IO_ERROR, itemIOError );
		}
		
		protected function releaseListeners( loader : Object ) : void
		{
			loader.removeEventListener( Event.COMPLETE, itemComplete ); 
			loader.removeEventListener( ProgressEvent.PROGRESS, itemProgress ); 
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, itemSecurityError );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, itemIOError );
		}	
		
		protected function putToQueue( record : LoaderRecord ) : void
		{
			//Запускаем загрузку объекта
			if ( loading.length < MAX_PARALLEL_REQUESTS )
			{
				loading.push( record );
				initLoad( record );
			}
			else //Ставим в очередь
			{
				inqueue.push( record );
			}
		}	
		
		protected function initLoad( record : LoaderRecord ) : void
		{
			_busy = true;
			setListeners( record.loader );
		}	
		
		protected function itemComplete( e : Event ) : void
		{
			var loader : Object =  e.currentTarget;
			
			releaseListeners( loader );
			
			//Удаляем загруженный объект из списка загрузки
			var loaderIndex : int = getRecordIndexByLoader( loading, loader );
			
			loading.splice( loaderIndex, 1 );
			
			//Если в списке ожидающих загрузку есть объекты, то запускаем загрузку одного из них
			if ( inqueue.length > 0 )
			{
				var next : LoaderRecord = inqueue.pop();
				loading.push( next );
				initLoad( next );
			}
			
			/*if ( e.type != Event.COMPLETE ) 
			{	
				try
				{
					dispatchEvent( e );
				}
				catch( error : SecurityError )
				{
					
				}
				catch( error : IOError )
				{
					
				}
			}*/
			
			_busy = inqueue.length > 0 && loading.length > 0;
			
			if ( ! _busy )
			{
				dispatchEvent( new Event( Event.COMPLETE ) );
			}	
		}
		
		protected function itemIOError( e : IOErrorEvent ) : void
		{	
			itemComplete( e );
			
		}
		
		protected function itemSecurityError( e : SecurityErrorEvent ) : void
		{
			itemComplete( e );
		}
		
		protected function itemProgress( e : ProgressEvent ) : void
		{
			
		}	
	}
}	