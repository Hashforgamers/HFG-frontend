'use client';

import { getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getPublicFirebaseEnv } from "@/lib/env";

const app = getApps()[0] ?? initializeApp(getPublicFirebaseEnv());

export const firebaseAuth = getAuth(app);
