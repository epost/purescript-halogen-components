-- | A halogen component for handling a file input button
-- | which handles the input by means of purescript-js-fileio
-- | (and which supports both text and binary input)
module Halogen.FileInputComponent where

import Prelude

import Data.Maybe (Maybe(..))

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.HTML.Core (ClassName(..))
import Data.MediaType (MediaType)
import Control.Monad.Aff (Aff)
import JS.FileIO (FILEIO, Filespec, loadTextFile, loadBinaryFileAsText)
import Halogen (IProp)
import Halogen.HTML.CSS (style)
import CSS.Display (display, displayNone)

type Context = {
    componentId :: String     -- the component id
  , isBinary    :: Boolean    -- does it handle binary as text or just simple text
  , prompt      :: String     -- the user prompt
  , accept      :: MediaType  -- the accepted media type(s)
  }

data Query a = LoadFile a

data Message = FileLoaded Filespec

type State = Maybe Filespec

component :: forall eff. Context -> H.Component HH.HTML Query Unit Message (Aff (fileio :: FILEIO | eff))
component ctx =
  H.component
    { initialState: const initialState
    , render: render ctx
    , eval: eval ctx
    , receiver: const Nothing
    }
  where

  initialState :: State
  initialState = Nothing


  render :: Context  -> State -> H.ComponentHTML Query
  render ctx state =
    HH.span
      [ HP.class_ $ ClassName "fileInput" ]
      [ -- the label is a hack to allow styling of file input which is
        -- otherwise impossible - see https://stackoverflow.com/questions/572768/styling-an-input-type-file-button
        HH.label
             [ HP.for ctx.componentId
             , HP.class_ $ ClassName "hoverable fileInputLabel"
             -- , HP.class_ $ ClassName "fileInputLabel"
             ]
             [ HH.text ctx.prompt ]
        -- we set the style to display none so that the label acts as a button
      , HH.input
          [ HE.onChange (HE.input_ LoadFile)
          , HP.type_ HP.InputFile
          , HP.id_  ctx.componentId
          , HP.accept ctx.accept
          , noDisplayStyle
          ]
      ]

  eval :: Context -> Query ~> H.ComponentDSL State Query Message (Aff (fileio :: FILEIO | eff))
  eval ctx = case _ of
    LoadFile next -> do
      filespec <-
         if ctx.isBinary then
           H.liftAff $ loadBinaryFileAsText ctx.componentId
         else
           H.liftAff $ loadTextFile ctx.componentId
      H.modify (\state -> Just filespec )
      H.raise $ FileLoaded filespec
      pure next

  noDisplayStyle :: ∀ i r. IProp (style :: String | r) i
  noDisplayStyle =
    style do
      display displayNone