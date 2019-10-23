package classes.api
{ 
    import flash.events.AsyncErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.NetStatusEvent;
    import flash.net.NetConnection;
    import flash.net.Responder;
    
    import mx.core.mx_internal;
    
    import classes.api.events.AMFErrorEvent;
    
    import handler.IChannel;
	
	use namespace mx_internal;
	
	public class AMFApi extends CustomEventDispatcher implements IChannel
	{
		/**
		 * Выполняется текущая операция 
		 */		
		private var _loading : Boolean;
		
		protected var nc : NetConnection;
		
		/**
		 * Очередь ожидающих выполнения запросов 
		 */		
		mx_internal var queue : Vector.<Call> = new Vector.<Call>(); 
		/**
		 * Текущий выполняемый запрос 
		 */		
		mx_internal var currentCall : Call;
		
		/**
		 * Функция обработки востановления соединения с сервером 
		 */		
		mx_internal var processErrorFunction : Function;
		
		public function AMFApi()
		{
			super();
			
			nc = new NetConnection();
			
			nc.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
			nc.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			nc.addEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError );
		}
		
		private function onAsyncError( e : AsyncErrorEvent ) : void
		{
			processError( e.text, e.errorID );
		}
		
		private function onIOError( e : IOErrorEvent ) : void
		{
			processError( e.text, e.errorID );
		}
		
		private function onNetStatus( e : NetStatusEvent ) : void
		{
			if ( e.info.level == 'error' )
			{
				processError( e.info.code, 1000 );
			}
		}
		
		protected function onFault( responds : Object ) : void
		{
			processError();
		}
		
		private function processError( message : String = null, code : int = 0 ) : void
		{
			_loading = false;
			
			if ( processErrorFunction != null )
			{
				if ( ! processErrorFunction.call( this, this/*, message, code.toString()*/ ) )
				 dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, message, code, currentCall ) );	
			}
			else
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, message, code, currentCall ) );
				next();
			}
			
			//Последний вызов
			//checkIfEndLoading();
		}
		
		private function onSuccess( responds : Object ) : void
		{
			_loading = false;
			
			if ( processErrorFunction != null )
			{
				dispatchEvent( new Event( Event.COMPLETE ) );	
			}
			
			//Проверяем стоит ли вызывать указанную ф-ию
			if ( beforeSuccessCall( responds ) )
			{
				currentCall.callback.call( this, responds, currentCall );
				next();
			}
			
			//Последний вызов
			//checkIfEndLoading();
		}
		
		/*private function checkIfEndLoading() : void
		{
			if ( queue.length == 0 )
			{
				trace( AMFEvent.END_LOADING );
				dispatchEvent( new AMFEvent( AMFEvent.END_LOADING ) );
			}
		}*/
		
		/**
		 * Вызывается перед вызовом ф-ии onSuccess и определяет стоит ли её вызывать
		 * Используется например, для контроля потери сессии 
		 * @param responds
		 * @return 
		 * 
		 */		
		protected function beforeSuccessCall( responds : Object ) : Boolean
		{
			return true;
		}
		
		public function get loading() : Boolean
		{
			return queue.length > 0;
		}
		
		/**
		 * Добавляет запрос в начало очереди 
		 * @param func
		 * @param callback
		 * @param params
		 * 
		 */		
		mx_internal function unshiftQueue( func : String, callback : Function, ...params ) : void
		{
			queue.unshift( new Call( func, callback, params ) );
		}
		
		/**
		 * Добавляет запрос в начало очереди 
		 * @param func
		 * @param callback
		 * @param params
		 * 
		 */		
		/*
		mx_internal function pushQueue( func : String, callback : Function, ...params ) : void
		{
			queue.push( new Call( func, callback, params ) );
		}
		*/
		/**
		 * Добавляет запрос в конец очереди 
		 * @param func
		 * @param callback
		 * @param params
		 * 
		 */		
		public function call( func : String, callback : Function, ...params ) : void
		{
			//trace( func );
			queue.push( new Call( func, callback, params ) );
			next();
		}
		
		private function applyCall( call : Call ) : void
		{
			_loading = true;
			nc.call.apply( nc, call.getData( new Responder( onSuccess, onFault ) ) );
		}
		
		public function next() : void
		{
			if ( ! _loading && queue.length > 0 )
			{
				//Первый вызов
				/*if ( queue.length == 1 )
				{
					dispatchEvent( new AMFEvent( AMFEvent.BEGIN_LOADING ) );
					trace( AMFEvent.BEGIN_LOADING );
				}*/
				
				currentCall = queue.shift();
				applyCall( currentCall );
			}
		}
		
		public function repair() : void
		{
			if ( currentCall )
			{
				applyCall( currentCall );
			}
		}
	}
}