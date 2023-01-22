import React, { useState, useEffect, useRef, ReactNode } from 'react'
import useRefresh from './useRefresh'

const useGetPublicSale = () => {
  const [publicSale, setPublicSale] = useState(false)
  const {slowRefresh, fastRefresh} = useRefresh()

  useEffect(() => {
    const sale = await apeContract.methods.publicSale().call()
  }, [])

  return publicSale
}

export default useGetPublicSale