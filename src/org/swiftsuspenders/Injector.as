/* * Copyright (c) 2009 the original author or authors * * Permission is hereby granted, free of charge, to any person obtaining a copy * of this software and associated documentation files (the "Software"), to deal * in the Software without restriction, including without limitation the rights * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell * copies of the Software, and to permit persons to whom the Software is * furnished to do so, subject to the following conditions: * * The above copyright notice and this permission notice shall be included in * all copies or substantial portions of the Software. * * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN * THE SOFTWARE. */package org.swiftsuspenders{	import flash.utils.Dictionary;	import flash.utils.Proxy;	import flash.utils.describeType;	import flash.utils.getDefinitionByName;	import flash.utils.getQualifiedClassName;	/**	 * @author tschneidereit	 */	public class Injector	{		/*******************************************************************************************		*								protected/ private properties							   *		*******************************************************************************************/		private var m_mappings : Dictionary;		private var m_singletons : Dictionary;		private var m_injectionPointLists : Dictionary;		private var m_constructorInjectionPoints : Dictionary;		private var m_successfulInjections : Dictionary;						/*******************************************************************************************		*								public methods											   *		*******************************************************************************************/		public function Injector()		{			m_mappings = new Dictionary();			m_singletons = new Dictionary();			m_injectionPointLists = new Dictionary();			m_constructorInjectionPoints = new Dictionary();			m_successfulInjections = new Dictionary(true);		}		public function mapValue(			whenAskedFor : Class, useValue : Object, named : String = null) : void		{			var config : InjectionConfig = new InjectionConfig(				whenAskedFor, useValue, InjectionConfig.INJECTION_TYPE_VALUE);			addMapping(config, named);		}		public function mapClass(			whenAskedFor : Class, instantiateClass : Class, named : String = null) : void		{			var config : InjectionConfig = new InjectionConfig(				whenAskedFor, instantiateClass, InjectionConfig.INJECTION_TYPE_CLASS);			addMapping(config, named);		}				public function mapSingleton(whenAskedFor : Class, named : String = null) : void		{			mapSingletonOf(whenAskedFor, whenAskedFor, named);		}		public function mapSingletonOf(			whenAskedFor : Class, useSingletonOf : Class, named : String = null) : void		{			var config : InjectionConfig = new InjectionConfig(				whenAskedFor, useSingletonOf, InjectionConfig.INJECTION_TYPE_SINGLETON);			addMapping(config, named);		}				public function injectInto(target : Object) : void		{			if (m_successfulInjections[target])			{				return;			}						//get injection points or cache them if this targets' class wasn't encountered before			var injectionPoints : Array;			var ctor : Class;			if (target is Proxy)			{				//for classes extending Proxy, we can't access the 'constructor' property because the 				//Proxy will throw if we try. So let's take the scenic route ...				var name : String = getQualifiedClassName(target);				ctor = Class(getDefinitionByName(name));			}			else			{				ctor = target.constructor;			}						injectionPoints = m_injectionPointLists[ctor] || getInjectionPoints(ctor);						for each (var injectionPoint : InjectionPoint in injectionPoints)			{				injectionPoint.applyInjection(target, this, m_singletons);			}			m_successfulInjections[target] = true;		}				public function instantiate(clazz:Class):*		{			var injectionPoint : InjectionPoint = m_constructorInjectionPoints[clazz];			if (!injectionPoint)			{				getInjectionPoints(clazz);				injectionPoint = m_constructorInjectionPoints[clazz];			}			var instance : * = injectionPoint.applyInjection(clazz, this, m_singletons);			injectInto(instance);			return instance;		}				public function unmap(clazz : Class, named : String = null) : void		{			var requestName : String = getQualifiedClassName(clazz);			if (named && m_mappings[named])			{				delete Dictionary(m_mappings[named])[requestName];			}			else			{				delete m_mappings[requestName];			}		}						/*******************************************************************************************		*								protected/ private methods								   *		*******************************************************************************************/		private function addMapping(config : InjectionConfig, named : String) : void		{			var requestName : String = getQualifiedClassName(config.request);			if (named)			{				var nameMappings : Dictionary = m_mappings[named];				if (!nameMappings)				{					nameMappings = m_mappings[named] = new Dictionary();				}				nameMappings[requestName] = config;			}			else			{				m_mappings[requestName] = config;			}		}				private function getInjectionPoints(clazz : Class) : Array		{			var injectionPoints : Array = m_injectionPointLists[clazz] = [];						var description : XML = describeType(clazz);			var node : XML;			var injectionPoint : InjectionPoint;			//get constructor injections			node = description.factory.constructor[0];			if (node)			{				m_constructorInjectionPoints[clazz] = new ConstructorInjectionPoint(node, m_mappings, clazz);			}			else			{				m_constructorInjectionPoints[clazz] = new NoParamsConstructorInjectionPoint();			}			//get injection points for variables			// This is where we have to wire in the XML...			for each (node in description.factory.*.(name() == 'variable' || name() == 'accessor').				metadata.(@name == 'Inject'))			{				injectionPoint = new VariableInjectionPoint(node, m_mappings);				injectionPoints.push(injectionPoint);			}			//get injection points for variables			for each (node in description.factory.method.metadata.(@name == 'Inject'))			{				injectionPoint = new MethodInjectionPoint(node, m_mappings);				injectionPoints.push(injectionPoint);			}						return injectionPoints;		}	}}