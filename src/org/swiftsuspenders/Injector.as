/*
 * Copyright (c) 2009-2011 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders
{
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	import org.swiftsuspenders.injectionpoints.InjectionPoint;
	import org.swiftsuspenders.injectionpoints.InjectionPointConfig;
	import org.swiftsuspenders.utils.ClassDescription;
	import org.swiftsuspenders.utils.ClassDescriptor;
	import org.swiftsuspenders.utils.XMLClassDescriptor;
	import org.swiftsuspenders.utils.getConstructor;

	public class Injector
	{
		//----------------------       Private / Protected Properties       ----------------------//
		private static var INJECTION_POINTS_CACHE : Dictionary = new Dictionary(true);


		private var _parentInjector : Injector;
        private var _applicationDomain:ApplicationDomain;
		private var _classDescriptor : ClassDescriptor;
		private var _mappings : Dictionary;
		private var _attendedToInjectees : Dictionary;


		//----------------------               Public Methods               ----------------------//
		public function Injector(xmlConfig : XML = null)
		{
			_mappings = new Dictionary();
			if (xmlConfig != null)
			{
				_classDescriptor = new XMLClassDescriptor(new Dictionary(true), xmlConfig);
			}
			else
			{
				_classDescriptor = new ClassDescriptor(INJECTION_POINTS_CACHE);
			}
			_attendedToInjectees = new Dictionary(true);
		}

		public function map(type : Class) : InjectionRule
		{
			return _mappings[type] || createRule(type);
		}

		public function mapNamed(type : Class, name : String) : InjectionRule
		{
			return _mappings[getQualifiedClassName(type) + name] || createNamedRule(type, name);
		}

		public function getMapping(requestType : Class) : InjectionRule
		{
			return _mappings[requestType] || getAncestorMapping(requestType);
		}

		public function getNamedMapping(requestType : Class, named : String = "") : InjectionRule
		{
			return _mappings[getQualifiedClassName(requestType) + named] ||
					getNamedAncestorMapping(requestType, named);
		}
		
		public function injectInto(target : Object) : void
		{
			if (_attendedToInjectees[target])
			{
				return;
			}
			_attendedToInjectees[target] = true;

			var injecteeDescription : ClassDescription =
					_classDescriptor.getDescription(getConstructor(target));

			var injectionPoints : Array = injecteeDescription.injectionPoints;
			var length : int = injectionPoints.length;
			for (var i : int = 0; i < length; i++)
			{
				var injectionPoint : InjectionPoint = injectionPoints[i];
				injectionPoint.applyInjection(target, this);
			}
		}
		
		public function instantiate(type : Class) : *
		{
			var typeDescription : ClassDescription = _classDescriptor.getDescription(type);
			var injectionPoint : InjectionPoint = typeDescription.ctor;
			var instance : * = injectionPoint.applyInjection(type, this);
			injectInto(instance);
			return instance;
		}

		public function unmap(type : Class) : void
		{
			var rule : InjectionRule = _mappings[type];
			if (!rule)
			{
				throw new InjectorError('Error while removing an injector mapping: ' +
						'No mapping defined for class ' + getQualifiedClassName(type));
			}
			rule.setProvider(null);
		}

		public function unmapNamed(type : Class, named : String) : void
		{
			var mapping : InjectionRule = _mappings[getQualifiedClassName(type) + named];
			if (!mapping)
			{
				throw new InjectorError('Error while removing an injector mapping: ' +
						'No mapping defined for class ' + getQualifiedClassName(type) +
						', named "' + named + '"');
			}
			mapping.setProvider(null);
		}

		public function hasMapping(type : Class) : Boolean
		{
			var rule : InjectionRule = getMapping(type);
			return rule && rule.hasProvider();
		}

		public function hasNamedMapping(type : Class, named : String) : Boolean
		{
			var rule : InjectionRule = getNamedMapping(type, named);
			return rule && rule.hasProvider();
		}

		public function getInstance(type : Class) : *
		{
			var mapping : InjectionRule = getMapping(type);
			if (!mapping || !mapping.hasProvider())
			{
				throw new InjectorError('Error while getting mapping response: ' +
						'No mapping defined for class ' + getQualifiedClassName(type));
			}
			return mapping.apply(this);
		}

		public function getInstanceNamed(type : Class, named : String) : *
		{
			var mapping : InjectionRule = getNamedMapping(type, named);
			if (!mapping || !mapping.hasProvider())
			{
				throw new InjectorError('Error while getting mapping response: ' +
						'No mapping defined for class ' + getQualifiedClassName(type) +
						', named "' + named + '"');
			}
			return mapping.apply(this);
		}
		
		public function createChildInjector(applicationDomain:ApplicationDomain=null) : Injector
		{
			var injector : Injector = new Injector();
            injector.setApplicationDomain(applicationDomain);
			injector.setParentInjector(this);
			return injector;
		}
        
        public function setApplicationDomain(applicationDomain:ApplicationDomain):void
        {
            _applicationDomain = applicationDomain;
        }
        
        public function getApplicationDomain():ApplicationDomain
        {
            return _applicationDomain ? _applicationDomain : ApplicationDomain.currentDomain;
        }

		public function setParentInjector(parentInjector : Injector) : void
		{
			//restore own map of worked injectees if parent injector is removed
			if (_parentInjector && !parentInjector)
			{
				_attendedToInjectees = new Dictionary(true);
			}
			_parentInjector = parentInjector;
			//use parent's map of worked injectees
			if (parentInjector)
			{
				_attendedToInjectees = parentInjector._attendedToInjectees;
			}
		}
		
		public function getParentInjector() : Injector
		{
			return _parentInjector;
		}

		public static function purgeInjectionPointsCache() : void
		{
			INJECTION_POINTS_CACHE = new Dictionary(true);
		}


		//----------------------             Internal Methods               ----------------------//
		internal function getAncestorMapping(whenAskedFor : Class) : InjectionRule
		{
			return _parentInjector ? _parentInjector.getMapping(whenAskedFor) : null;
		}
		internal function getNamedAncestorMapping(
				whenAskedFor : Class, named : String = null) : InjectionRule
		{
			return _parentInjector ? _parentInjector.getNamedMapping(whenAskedFor, named) : null;
		}

		public function getRuleForInjectionPointConfig(
				config : InjectionPointConfig) : InjectionRule
		{
			var type : Class = Class(getApplicationDomain().getDefinition(config.typeName));
			if (config.injectionName)
			{
				return getNamedMapping(type, config.injectionName);
			}
			return getMapping(type);
		}


		//----------------------         Private / Protected Methods        ----------------------//
		private function createRule(requestType : Class) : InjectionRule
		{
			return (_mappings[requestType] = new InjectionRule(requestType));
		}

		private function createNamedRule(requestType : Class, name : String = '') : InjectionRule
		{
			return (_mappings[getQualifiedClassName(requestType) + name] =
					new NamedInjectionRule(requestType, ''));
		}
	}
}