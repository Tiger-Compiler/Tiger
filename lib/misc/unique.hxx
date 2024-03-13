/**
 ** \file misc/unique.hxx
 ** \brief Inline implementation of misc::unique.
 */

#pragma once

#include <utility>
#include <misc/contract.hh>
#include <misc/unique.hh>

namespace misc
{
  template <typename T, class C> unique<T, C>::unique(const data_type& s) 
  /** \brief Following the Flyweight design pattern, set the attribute to a
       unique reference of value s. You might want to check out std::set methods
       on cppreference.com. */
       // DONE
  { 
    auto res = object_set_instance().insert(s);
    
    
    obj_ = &(*(res.first));
    
  }

  template <typename T, class C>
  typename unique<T, C>::object_set_type& unique<T, C>::object_set_instance()
  {
    // DONE: Some code was deleted here (Classical Singleton pattern, a la Scott Meyers').
    /** \brief Create a persistent instance of a set which would hold each value. */


    static auto persist_set =  unique<T,C>::object_set_type();
    return persist_set;
  }

  template <typename T, class C>
  typename unique<T, C>::object_size_type unique<T, C>::object_map_size()
  {
    // DONE: Some code was deleted here.
    object_set_instance().size();
  }

  template <typename T, class C>
  inline const typename unique<T, C>::data_type& unique<T, C>::get() const
  {
    // DONE: Some code was deleted here.
    return *obj_;
  }

  template <typename T, class C>
  inline unique<T, C>::operator const data_type&() const
  {
    // DONE: Some code was deleted here (Check Typecasts overload).
    return static_cast<T>(obj_);
  }

  template <typename T, class C>
  inline typename unique<T, C>::value_type&
  unique<T, C>::operator=(const value_type& rhs)
  {
    if (this != &rhs)
      obj_ = rhs.obj_;
    return *this;
  }

  template <typename T, class C>
  inline bool unique<T, C>::operator==(const value_type& rhs) const
  {
    //std::cerr << "adress 1: " << obj_ << "\n";
    //std::cerr << "adress 2: " << rhs.obj_ << "\n";
    return obj_ == rhs.obj_;
  }

  template <typename T, class C>
  inline bool unique<T, C>::operator!=(const value_type& rhs) const
  {
    return !operator==(rhs);
  }

  template <typename T, class C>
  inline bool unique<T, C>::operator<(const value_type& rhs) const
  {
    C cmp;
    assertion(obj_);
    assertion(rhs.obj_);
    return cmp(*obj_, *rhs.obj_);
  }

  template <typename T, class C>
  inline std::ostream& operator<<(std::ostream& ostr, const unique<T, C>& the)
  {
    return ostr << the.get();
  }

} // namespace misc
