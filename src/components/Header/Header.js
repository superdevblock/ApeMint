import React from 'react';
import { ChakraProvider, useDisclosure } from "@chakra-ui/react";
import { Flex } from '@chakra-ui/react';
import Layout from "../Layout";
import ConnectButton from "../ConnectButton";
import AccountModal from "../AccountModal";

const Header = () => {

    const { isOpen, onOpen, onClose } = useDisclosure();

    return (
        <header id="header container" >
            {/* Navbar */}
            <nav data-aos="zoom-out" data-aos-delay={800} className="">
            <div  style={{display:"flex", justifyContent:"center", alignItems:"center", flexWrap:"wrap"}}>
                < a href='https://www.apeproject.io/' style={{height:"50px"}}>
                    <img className="" style={{height:"100%"}} src="img/logo.png"  alt="sticky brand-logo" />
                </a>
                <span style={{flex:"1"}}></span>           
                <span className="" style={{marginTop:20}}>
                    <ConnectButton  handleOpenModal={onOpen} />
                    <AccountModal isOpen={isOpen} onClose={onClose} />                    
                </span>
            </div>
        </nav>
        </header>
    );
};

export default Header;