-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 14, 2021 at 07:37 AM
-- Server version: 10.4.18-MariaDB
-- PHP Version: 8.0.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `object`
--

-- --------------------------------------------------------

--
-- Table structure for table `matext`
--

CREATE TABLE `matext` (
  `mtID` int(8) NOT NULL,
  `mtText` varchar(128) CHARACTER SET latin1 NOT NULL,
  `mtX` float NOT NULL DEFAULT 0,
  `mtY` float NOT NULL DEFAULT 0,
  `mtZ` float NOT NULL DEFAULT 0,
  `mtRX` float NOT NULL DEFAULT 0,
  `mtRY` float NOT NULL,
  `mtRZ` float NOT NULL DEFAULT 0,
  `mtInterior` int(6) NOT NULL DEFAULT 0,
  `mtWorld` int(6) NOT NULL DEFAULT 0,
  `mtBold` int(6) NOT NULL DEFAULT 0,
  `mtColor` int(4) NOT NULL DEFAULT 0,
  `mtSize` int(12) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `matext`
--

INSERT INTO `matext` (`mtID`, `mtText`, `mtX`, `mtY`, `mtZ`, `mtRX`, `mtRY`, `mtRZ`, `mtInterior`, `mtWorld`, `mtBold`, `mtColor`, `mtSize`) VALUES
(2, 'Testis', 1962.08, 1339.3, 9.2578, 0, 0, 84.1461, 0, 0, 0, 1, 20),
(3, 'HALO ANJ', 1961.78, 1330.13, 8.3878, 0, 0, 128.821, 0, 0, 0, 2, 30);

-- --------------------------------------------------------

--
-- Table structure for table `object`
--

CREATE TABLE `object` (
  `objid` int(8) NOT NULL,
  `objectModel` int(8) NOT NULL DEFAULT 0,
  `objectX` float NOT NULL DEFAULT 0,
  `objectY` float NOT NULL DEFAULT 0,
  `objectZ` float NOT NULL DEFAULT 0,
  `objectRX` float NOT NULL DEFAULT 0,
  `objectRY` float NOT NULL DEFAULT 0,
  `objectRZ` float NOT NULL DEFAULT 0,
  `objectInterior` int(8) NOT NULL DEFAULT 0,
  `objectWorld` int(8) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `object`
--

INSERT INTO `object` (`objid`, `objectModel`, `objectX`, `objectY`, `objectZ`, `objectRX`, `objectRY`, `objectRZ`, `objectInterior`, `objectWorld`) VALUES
(8, 4642, 1961.82, 1343.91, 9.7446, 0, 0, 92.9195, 0, 0),
(9, 1642, 1961.94, 1331.59, 9.2578, 0, 0, 179.921, 0, 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `matext`
--
ALTER TABLE `matext`
  ADD PRIMARY KEY (`mtID`);

--
-- Indexes for table `object`
--
ALTER TABLE `object`
  ADD PRIMARY KEY (`objid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `matext`
--
ALTER TABLE `matext`
  MODIFY `mtID` int(8) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `object`
--
ALTER TABLE `object`
  MODIFY `objid` int(8) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
